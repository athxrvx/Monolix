use std::env;
use std::ffi::OsString;
use std::io::{self, BufRead, IsTerminal, Write};
use std::path::{Path, PathBuf};
use std::process::{self, Command, Output, Stdio};
use std::sync::mpsc;
use std::thread;
use std::time::Instant;

const HELP: &str = r#"kuro — Kuro system and desktop manager

Usage: kuro [OPTIONS] COMMAND [ARGS...]

Global options:
  -!, -n, --dry-run     Print commands without running them
  -f, --flake PATH      Use a specific flake directory
  -p, --profile NAME    Select a system profile (default: KURO_PROFILE or athena)
  -v, --verbose         Show commands as they run
  --no-color            Disable colored output
  -h, --help            Show this help

Build and activate:
  sync, switch, s [PROFILE]  Build and activate the system and Home Manager
  boot, bt [PROFILE]         Build and set as default for next boot (no live switch)
  home [PROFILE]             Build and activate Home Manager only
  build, b [PROFILE]         Build without activating
  test [PROFILE]             Activate temporarily until reboot
  check [PROFILE]            Evaluate the flake without building

Inspect and maintain:
  status                     Show current system and Home Manager generations
  generations [system|home]  List available generations
  jump [GENERATION]          Switch Home Manager generation (no number rolls back)
  jump --pick                Choose a Home Manager generation with fzf
  profile, pr                List available system profiles
  info                       Show flake, profile, and tool versions
  doctor                     Check the local setup and required commands
  path                       Print the detected flake directory
  update [INPUT]             Update flake inputs and write the flake.lock
  clean [--system] [--keep COUNT]
                             Clean old Home Manager generations, or system with --system
  gc [--system]              Collect unreachable store paths
  edit [FILE]                Open the flake or a file in it with $EDITOR
  menu                       Pick a kuro command with fzf

Temporary packages:
  search QUERY               Search Nixpkgs for a package
  run PACKAGE [ARGS...]      Run a package once without installing it
  try PACKAGE...             Open a temporary shell with packages
  fhs [COMMAND...]           Open an FHS shell or run a command inside it

Environment:
  KURO_FLAKE      Config flake directory (default ~/.config/nixconfig)
  KURO_PROFILE    Default profile (athena)
  KURO_USER       Home Manager username (default: atharva)

Examples:
  kuro update
  kuro sync
  kuro --dry-run home
  kuro status
  kuro clean --keep 5
  kuro search fastfetch
  kuro run hello --greeting hi
  kuro try ripgrep fd
  kuro fhs ./some-linux-installer
  kuro jump --pick

Profiles: athena (Hyprland + Kuro)
"#;

#[derive(Default)]
struct Options {
    dry_run: bool,
    verbose: bool,
    no_color: bool,
    flake_override: Option<PathBuf>,
    profile: String,
    user: String,
}

struct App {
    options: Options,
    flake: Option<PathBuf>,
    color: bool,
}

impl App {
    fn new() -> Self {
        let options = Options {
            profile: env::var("KURO_PROFILE").or_else(|_| env::var("ATHENA_PROFILE")).unwrap_or_else(|_| "athena".into()),
            user: env::var("KURO_USER").or_else(|_| env::var("ATHENA_USER")).unwrap_or_else(|_| "atharva".into()),
            flake_override: env::var_os("KURO_FLAKE").or_else(|| env::var_os("ATHENA_FLAKE")).map(PathBuf::from),
            ..Options::default()
        };
        let color = io::stdout().is_terminal()
            && env::var_os("NO_COLOR").is_none()
            && env::var_os("TERM").as_deref() != Some(std::ffi::OsStr::new("dumb"));
        Self { options, flake: None, color }
    }

    // ── styling ──────────────────────────────────────────────────────────

    fn styled(&self, code: &str, text: &str) -> String {
        if self.color { format!("\x1b[{code}m{text}\x1b[0m") } else { text.to_string() }
    }
    fn bold(&self, text: &str) -> String { self.styled("1", text) }
    fn cyan(&self, text: &str) -> String { self.styled("38;5;110", text) }
    fn bright_cyan(&self, text: &str) -> String { self.styled("1;38;5;117", text) }
    fn magenta(&self, text: &str) -> String { self.styled("38;5;176", text) }
    fn green(&self, text: &str) -> String { self.styled("38;5;114", text) }
    fn red(&self, text: &str) -> String { self.styled("1;38;5;167", text) }
    fn yellow(&self, text: &str) -> String { self.styled("38;5;179", text) }
    fn dim(&self, text: &str) -> String { self.styled("38;5;244", text) }

    fn fail(&self, message: impl AsRef<str>) -> ! {
        eprintln!("{}  {} {}", self.red("✗"), self.bold("kuro"), message.as_ref());
        process::exit(2)
    }
    fn ok(&self, text: &str) { println!("  {}  {}", self.green("✓"), text); }
    fn warn(&self, text: &str) { eprintln!("  {}  {}", self.yellow("!"), text); }

    // A labelled section with a short supporting footer.
    fn section(&self, title: &str) {
        println!();
        println!("  {}", self.bold(title));
    }
    fn section_end(&self, detail: &str) {
        println!("  {}\n", self.dim(detail));
    }

    // Announce an interactive handoff (fzf, nix shell, editor) without boxing
    // child output: those tools need inherited stdio to draw their own UI.
    fn handoff(&self, command: &str, detail: &str, args: &[OsString]) {
        println!();
        println!("{}  {}", self.bright_cyan(&format!("kuro {command}")), self.dim(detail));
        println!("  {} {}", self.dim("$"), command_string(args));
        println!("  {}", self.dim("interactive · handing off"));
        println!();
    }

    // Keep task context compact and readable in terminals and logs.
    fn header(&self, command: &str, subtitle: &str) {
        if !self.color {
            println!("kuro {command} — {subtitle}");
            return;
        }
        let flake = self.flake.as_ref().map(|p| shorten_home(p)).unwrap_or_else(|| "...".into());
        println!();
        println!("{}", self.bright_cyan(&format!("kuro {command}")));
        println!("  {}  {}", self.dim("task   "), subtitle);
        println!("  {}  {}", self.dim("flake  "), self.magenta(&flake));
        println!("  {}  {}", self.dim("profile"), self.magenta(&self.options.profile));
        println!();
    }

    // ── flake / profile ──────────────────────────────────────────────────

    fn require_flake(&mut self) -> PathBuf {
        if let Some(path) = &self.flake { return path.clone(); }
        let flake = match &self.options.flake_override {
            Some(path) => {
                let path = absolute_path(path);
                if !path.join("flake.nix").is_file() { self.fail(format!("no flake.nix in '{}'", path.display())); }
                path
            }
            None => find_flake().unwrap_or_else(|| self.fail("could not find flake.nix; run this inside the config or pass --flake PATH")),
        };
        self.flake = Some(flake.clone());
        flake
    }

    fn profile(&self, profile: &str) {
        if profile != "athena" {
            self.fail(format!("unknown profile '{profile}' (choose athena)"));
        }
    }

    fn flake_ref(&mut self) -> String { format!("path:{}", self.require_flake().display()) }

    // ── process helpers ──────────────────────────────────────────────────

    // Plain, inherited-stdio execution for interactive commands (fzf, nix
    // shell, editors) where a progress bar would get in the way.
    fn command(&self, args: &[OsString]) -> ! {
        if args.is_empty() { self.fail("internal error: empty command"); }
        if self.options.dry_run {
            print!("{} ", self.cyan("+"));
            print_args(args);
            process::exit(0);
        }
        if self.options.verbose { print!("  "); print_args(args); }
        let status = Command::new(&args[0]).args(&args[1..]).status()
            .unwrap_or_else(|error| self.fail(format!("could not run {:?}: {error}", args[0])));
        process::exit(status.code().unwrap_or(1));
    }

    fn capture(&self, args: &[OsString]) -> Output {
        Command::new(&args[0]).args(&args[1..]).output()
            .unwrap_or_else(|error| self.fail(format!("could not run {:?}: {error}", args[0])))
    }

    // Run a command and stream every stdout/stderr line live inside a bordered
    // box. Nothing is swallowed and there is no fake animated progress: the
    // child's own output is the progress. stdout is still collected so `home`
    // can read the activation path it prints.
    fn run_task(&self, args: &[OsString], label: &str) -> TaskResult {
        if self.options.dry_run { self.run(args); return TaskResult { success: true, code: 0, stdout: String::new() }; }
        if args.is_empty() { self.fail("internal error: empty command"); }
        if self.options.verbose { print!("  "); print_args(args); }

        let mut child = Command::new(&args[0])
            .args(&args[1..])
            .stdout(Stdio::piped())
            .stderr(Stdio::piped())
            .spawn()
            .unwrap_or_else(|error| self.fail(format!("could not run {:?}: {error}", args[0])));

        let (tx, rx) = mpsc::channel::<OutputLine>();
        let mut readers = Vec::new();
        if let Some(stream) = child.stdout.take() {
            let tx = tx.clone();
            readers.push(thread::spawn(move || {
                let mut reader = io::BufReader::new(stream);
                let mut line = String::new();
                loop {
                    line.clear();
                    match reader.read_line(&mut line) {
                        Ok(0) | Err(_) => break,
                        Ok(_) => {
                            let text = line.trim_end().to_string();
                            if tx.send(OutputLine { stdout: true, text }).is_err() { break; }
                        }
                    }
                }
            }));
        }
        if let Some(stream) = child.stderr.take() {
            let tx = tx.clone();
            readers.push(thread::spawn(move || {
                let mut reader = io::BufReader::new(stream);
                let mut line = String::new();
                loop {
                    line.clear();
                    match reader.read_line(&mut line) {
                        Ok(0) | Err(_) => break,
                        Ok(_) => {
                            let text = line.trim_end().to_string();
                            if tx.send(OutputLine { stdout: false, text }).is_err() { break; }
                        }
                    }
                }
            }));
        }
        drop(tx);

        let mut output = OutputBox::new(self.color, label);
        let mut stdout_text = String::new();
        let mut lines = 0usize;
        for item in rx {
            if item.stdout { stdout_text.push_str(&item.text); stdout_text.push('\n'); }
            if item.text.trim().is_empty() { continue; }
            output.line(&item.text, item.stdout);
            lines += 1;
        }
        for reader in readers { let _ = reader.join(); }

        let wait = child.wait().unwrap_or_else(|error| self.fail(format!("could not wait for {:?}: {error}", args[0])));
        let success = wait.success();
        let code = wait.code().unwrap_or(1);
        let message = if success {
            format!("{label} complete · {lines} lines")
        } else {
            format!("{label} failed (exit {code}) after {lines} lines")
        };
        let seconds = output.started.elapsed().as_secs();
        output.finish(success, &message);
        self.notify_task(label, success, seconds);
        TaskResult { success, code, stdout: stdout_text }
    }

    fn notify_task(&self, label: &str, success: bool, seconds: u64) {
        if seconds < 5 { return; }
        let Some(notify_send) = find_executable("notify-send") else { return; };
        let title = format!("Kuro · {label}");
        let body = if success {
            format!("Completed in {}.", format_duration(seconds))
        } else {
            format!("Failed after {}.", format_duration(seconds))
        };
        let urgency = if success { "normal" } else { "critical" };
        let _ = Command::new(notify_send)
            .args(["--app-name=Kuro", "--urgency", urgency, &title, &body])
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .spawn();
    }

    fn command_task(&self, args: &[OsString], label: &str) -> ! {
        let result = self.run_task(args, label);
        if !result.success { process::exit(result.code); }
        process::exit(0);
    }

    fn generations(&self, target: &str) {
        let profile_path = match target {
            "home" => home_profile_path(),
            "system" => PathBuf::from("/nix/var/nix/profiles/system"),
            _ => self.fail(format!("unknown generation target '{target}' (choose system or home)")),
        };
        if target == "home" && profile_path.symlink_metadata().is_err() {
            println!("\n{}", self.bold("home generations"));
            println!("  {} {}", self.green("●"), self.dim("integrated with system profile (useUserPackages = true)"));
            println!("  {}\n", self.dim("managed via nixos-rebuild"));
            return;
        }
        // nix-env opens the profile lock even for read-only listing, so the
        // system profile still needs root; the user profile does not.
        let args: Vec<OsString> = if target == "system" {
            os_args(&["sudo", "nix-env", "--profile", &profile_path.to_string_lossy(), "--list-generations"])
        } else {
            os_args(&["nix-env", "--profile", &profile_path.to_string_lossy(), "--list-generations"])
        };
        let output = self.capture(&args);
        if !output.status.success() {
            io::stderr().write_all(&output.stderr).ok();
            self.fail(format!("could not list {target} generations"));
        }
        let text = String::from_utf8_lossy(&output.stdout);
        let rows: Vec<&str> = text.lines().map(str::trim).filter(|line| !line.is_empty()).collect();
        println!("\n{}", self.bold(&format!("{target} generations")));
        for row in &rows {
            let marker = if row.contains("(current)") { self.green("●") } else { self.dim("○") };
            println!("  {}  {}", marker, self.dim(row));
        }
        if rows.is_empty() { println!("  {}", self.dim("(none)")); }
        println!("  {}\n", self.dim(&format!("{} generation(s) · {}", rows.len(), profile_path.display())));
    }

    fn delete_generations(&self, target: &str, keep: Option<&str>) {
        if let Some(count) = keep {
            if count.parse::<u32>().map(|n| n > 0).unwrap_or(false) == false {
                self.fail("--keep requires a positive generation count");
            }
        }
        let generation_selector = keep.map(|count| format!("+{count}")).unwrap_or_else(|| "old".into());
        let description = keep.map(|count| format!("all but the newest {count}")).unwrap_or_else(|| "all old generations".into());
        let (profile, privileged) = if target == "home" { (home_profile_path(), false) } else { (PathBuf::from("/nix/var/nix/profiles/system"), true) };
        if target == "home" && profile.symlink_metadata().is_err() && !self.options.dry_run {
            self.warn(&format!("no Home Manager generation profile found at {}", profile.display()));
            return;
        }
        self.header("clean", &format!("delete {description} from the {target} profile"));
        let mut args: Vec<OsString> = if privileged { vec!["sudo".into()] } else { vec![] };
        args.extend(["nix-env".into(), "--profile".into(), profile.clone().into_os_string(), "--delete-generations".into(), generation_selector.into()]);
        let deleted = self.run_task(&args, "Delete generations");
        if !deleted.success { process::exit(deleted.code); }
        let mut gc: Vec<OsString> = if privileged { vec!["sudo".into()] } else { vec![] };
        gc.extend(["nix-collect-garbage".into()]);
        let collected = self.run_task(&gc, "Garbage collection");
        if !collected.success { process::exit(collected.code); }
        self.ok(&format!("{target} generations cleaned · {description} · profile {}", profile.display()));
    }

    fn run(&self, args: &[OsString]) {
        if self.options.dry_run {
            print!("{} ", self.cyan("+"));
            print_args(args);
        } else {
            if self.options.verbose { print!("  "); print_args(args); }
            let status = Command::new(&args[0]).args(&args[1..]).status()
                .unwrap_or_else(|error| self.fail(format!("could not run {:?}: {error}", args[0])));
            if !status.success() { process::exit(status.code().unwrap_or(1)); }
        }
    }

    // ── commands ─────────────────────────────────────────────────────────

    fn execute(&mut self, command: &str, args: &[OsString]) {
        match command {
            "help" | "h" => self.print_help(),
            "menu" => self.menu(),
            "path" => {
                let flake = self.require_flake();
                self.section("flake");
                println!("  {}", self.magenta(&flake.display().to_string()));
                self.section_end(&shorten_home(&flake));
            }
            "profile" | "pr" => {
                self.section("profiles");
                println!("  {:<9}  {}", self.bright_cyan("athena"), self.dim("Hyprland + Kuro · default"));
                self.section_end("1 profile available");
            }
            "info" => {
                let flake = self.require_flake();
                self.section("kuro info");
                println!("  {:<9}  {}", self.bright_cyan("flake"), self.magenta(&shorten_home(&flake)));
                println!("  {:<9}  {}", self.bright_cyan("profile"), self.magenta(&self.options.profile));
                println!("  {:<9}  {}", self.bright_cyan("user"), self.magenta(&self.options.user));
                println!("  {:<9}  {}", self.bright_cyan("home state"), self.dim(&home_profile_path().display().to_string()));
                let version = self.capture(&os_args(&["nix", "--version"]));
                if version.status.success() {
                    println!("  {:<9}  {}", self.bright_cyan("nix"), self.dim(String::from_utf8_lossy(&version.stdout).trim()));
                }
                self.section_end("info complete");
            }
            "doctor" => {
                self.profile(&self.options.profile);
                let flake = self.require_flake();
                self.header("doctor", "check local setup and dependencies");
                let mut ok = 0;
                let mut missing = 0;
                self.section("Flake integrity");
                if flake.join("flake.nix").is_file() { self.ok(&format!("flake.nix found in {}", shorten_home(&flake))); ok += 1; } else { self.fail("flake.nix is missing"); }
                if flake.join("flake.lock").is_file() { self.ok("flake.lock found"); ok += 1; } else { self.warn("flake.lock is missing; run 'kuro update'"); missing += 1; }
                self.section("Core system tools");
                for tool in ["nix", "nixos-rebuild", "sudo", "git"] {
                    match find_executable(tool) {
                        Some(path) => { self.ok(&format!("{tool}: {}", path.display())); ok += 1; }
                        None => { self.warn(&format!("{tool} is not in PATH")); missing += 1; }
                    }
                }
                self.section("Desktop tools");
                for tool in ["hyprland", "fzf"] {
                    match find_executable(tool) {
                        Some(path) => { self.ok(&format!("{tool}: {}", path.display())); ok += 1; }
                        None => { self.warn(&format!("{tool} is not in PATH")); missing += 1; }
                    }
                }
                self.section_end(&format!("{ok} ok · {missing} missing/warning(s)"));
            }
            "status" => {
                self.profile(&self.options.profile);
                let flake_label = shorten_home(&self.require_flake());
                self.header("status", &format!("profile {} · {}", self.options.profile, flake_label));
                self.generations("system");
                self.generations("home");
            }
            "generations" => {
                if args.len() > 1 { self.fail("usage: kuro generations [system|home]"); }
                match args.first().and_then(|arg| arg.to_str()).unwrap_or("all") {
                    "all" => { self.generations("system"); self.generations("home"); }
                    target => self.generations(target),
                }
            }
            "pull" | "update" => {
                if args.len() > 1 { self.fail(format!("usage: kuro {command} [INPUT]")); }
                let subtitle = match args.first().and_then(|a| a.to_str()) {
                    Some(input) => format!("refresh flake input {input}"),
                    None => "refresh all flake inputs".to_string(),
                };
                self.header(command, &subtitle);
                let mut nix_args = os_args(&["nix", "flake", "update"]);
                if let Some(input) = args.first() { nix_args.push(input.clone()); }
                let flake_ref = self.flake_ref();
                nix_args.extend(["--flake".into(), flake_ref.into()]);
                self.command_task(&nix_args, "Flake update");
            }
            "check" => {
                if args.len() > 1 { self.fail("usage: kuro check [PROFILE]"); }
                let target = args.first().and_then(|s| s.to_str()).unwrap_or(&self.options.profile).to_string();
                self.profile(&target);
                self.header("check", &format!("evaluate profile {target}"));
                let flake_ref = self.flake_ref();
                self.command_task(&["nix".into(), "flake".into(), "check".into(), "--no-build".into(), "--show-trace".into(), flake_ref.into()], "Flake check");
            }
            "gc" => {
                if args.is_empty() {
                    self.header("gc", "collect unreachable store paths · user profile");
                    self.command_task(&os_args(&["nix-collect-garbage"]), "Garbage collection");
                } else if args.len() == 1 && args[0] == "--system" {
                    self.header("gc", "collect unreachable store paths · system profile");
                    self.command_task(&os_args(&["sudo", "nix-collect-garbage"]), "Garbage collection");
                } else {
                    self.fail("usage: kuro gc [--system]");
                }
            }
            "clean" => {
                let (system, keep) = parse_clean_args(self, args, "kuro clean [--system] [--keep COUNT]");
                self.delete_generations(if system { "system" } else { "home" }, keep);
            }
            "system" => {
                if args.first().and_then(|s| s.to_str()) != Some("clean") { self.fail("usage: kuro system clean [--keep COUNT]"); }
                let (_, keep) = parse_clean_args(self, &args[1..], "kuro system clean [--keep COUNT]");
                self.delete_generations("system", keep);
            }
            "sync" | "switch" | "s" => {
                if args.len() > 1 { self.fail(format!("usage: kuro {command} [PROFILE]")); }
                let target = args.first().and_then(|s| s.to_str()).unwrap_or(&self.options.profile).to_string();
                self.profile(&target);
                self.header(command, &format!("switch profile {target} (rebuild and activate)"));
                let flake_ref = self.flake_ref();
                self.command_task(&["sudo".into(), "nixos-rebuild".into(), "switch".into(), "--flake".into(), format!("{flake_ref}#{target}").into()], "System switch");
            }
            "boot" | "bt" => {
                if args.len() > 1 { self.fail(format!("usage: kuro {command} [PROFILE]")); }
                let target = args.first().and_then(|s| s.to_str()).unwrap_or(&self.options.profile).to_string();
                self.profile(&target);
                self.header(command, &format!("stage profile {target} for next boot (no live switch)"));
                let flake_ref = self.flake_ref();
                self.command_task(&["sudo".into(), "nixos-rebuild".into(), "boot".into(), "--flake".into(), format!("{flake_ref}#{target}").into()], "Bootloader update");
            }
            "build" | "b" => {
                if args.len() > 1 { self.fail(format!("usage: kuro {command} [PROFILE]")); }
                let target = args.first().and_then(|s| s.to_str()).unwrap_or(&self.options.profile).to_string();
                self.profile(&target);
                self.header(command, &format!("build profile {target} without activating"));
                let flake_ref = self.flake_ref();
                self.command_task(&["nix".into(), "build".into(), format!("{flake_ref}#nixosConfigurations.{target}.config.system.build.toplevel").into(), "--no-link".into(), "--print-out-paths".into()], "System build");
            }
            "test" => {
                if args.len() > 1 { self.fail("usage: kuro test [PROFILE]"); }
                let target = args.first().and_then(|s| s.to_str()).unwrap_or(&self.options.profile).to_string();
                self.profile(&target);
                self.header("test", &format!("test profile {target} temporarily (reverts on reboot)"));
                let flake_ref = self.flake_ref();
                self.command_task(&["sudo".into(), "nixos-rebuild".into(), "test".into(), "--flake".into(), format!("{flake_ref}#{target}").into()], "System test");
            }
            "home" => {
                if args.len() > 1 { self.fail("usage: kuro home [PROFILE]"); }
                let target = args.first().and_then(|s| s.to_str()).unwrap_or(&self.options.profile).to_string();
                self.profile(&target);
                let attr = format!("nixosConfigurations.{target}.config.home-manager.users.{}.home.activationPackage", self.options.user);
                let flake_ref = self.flake_ref();
                let installable = format!("{flake_ref}#{attr}");
                let build = os_args(&["nix", "build", &installable, "--no-link", "--print-out-paths"]);
                self.header("home", &format!("build Home Manager for {target}"));
                if self.options.dry_run {
                    self.run(&build);
                    println!("+ activate the resulting Home Manager package as the current user");
                } else {
                    let build_result = self.run_task(&build, "Home Manager build");
                    if !build_result.success { process::exit(build_result.code); }
                    let activation = build_result.stdout.lines().rev().find(|l| l.starts_with("/nix/store/")).unwrap_or(build_result.stdout.trim()).trim().to_string();
                    let script = Path::new(&activation).join("activate");
                    if !script.is_file() { self.fail(format!("Home Manager activation script missing from {activation}")); }
                    let activate_result = self.run_task(&[script.into_os_string()], "Home activation");
                    if !activate_result.success { process::exit(activate_result.code); }
                }
            }
            "jump" => self.jump(args),
            "try" => {
                if args.is_empty() { self.fail("usage: kuro try PACKAGE..."); }
                let mut nix_args = os_args(&["nix", "shell"]);
                for package in args { let package = package.to_string_lossy(); nix_args.push(if package.contains('#') { package.into_owned().into() } else { format!("nixpkgs#{package}").into() }); }
                self.handoff("try", "temporary package shell", &nix_args);
                self.command(&nix_args);
            }
            "run" => {
                if args.is_empty() { self.fail("usage: kuro run PACKAGE [ARGS...]"); }
                let package = args[0].to_string_lossy();
                let mut nix_args = vec!["nix".into(), "run".into(), (if package.contains('#') { package.into_owned() } else { format!("nixpkgs#{package}") }).into(), "--".into()];
                nix_args.extend_from_slice(&args[1..]);
                self.handoff("run", "one-off package run", &nix_args);
                self.command(&nix_args);
            }
            "search" => {
                if args.len() != 1 { self.fail("usage: kuro search QUERY"); }
                self.header("search", &format!("nixpkgs · {}", args[0].to_string_lossy()));
                self.command_task(&["nix".into(), "search".into(), "nixpkgs".into(), args[0].clone()], "Package search");
            }
            "fhs" => {
                let mut command = os_args(&["nix", "shell", "nixpkgs#steam-run", "--command", "steam-run"]);
                if args.is_empty() { command.extend(["zsh".into(), "-i".into()]); } else { command.extend_from_slice(args); }
                self.handoff("fhs", "FHS-compatible shell", &command);
                self.command(&command);
            }
            "edit" => {
                if args.len() > 1 { self.fail("usage: kuro edit [FILE]"); }
                let editor = env::var("EDITOR").or_else(|_| env::var("VISUAL")).unwrap_or_else(|_| "hx".into());
                let target = args.first().and_then(|s| s.to_str()).unwrap_or("flake.nix");
                let target = PathBuf::from(target);
                let target = if target.is_absolute() { target } else { self.require_flake().join(target) };
                if !target.exists() { self.fail(format!("file not found: {}", target.display())); }
                let description = format!("open {}", target.display());
                let mut editor_parts = editor.split_whitespace();
                let editor_bin = editor_parts.next().unwrap_or("hx");
                let mut editor_args: Vec<OsString> = editor_parts.map(Into::into).collect(); editor_args.push(target.into_os_string());
                let mut all = vec![OsString::from(editor_bin)]; all.extend_from_slice(&editor_args);
                self.handoff("edit", &description, &all);
                self.command_with(editor_bin, &editor_args);
            }
            "completions" => {
                if args.len() != 1 { self.fail("usage: kuro completions zsh|fish"); }
                self.print_completion(args[0].to_string_lossy().as_ref());
            }
            _ => self.fail(format!("unknown command '{command}' (run 'kuro help')")),
        }
    }

    fn command_with(&self, program: &str, args: &[OsString]) -> ! {
        if self.options.dry_run {
            let mut all = vec![program.into()]; all.extend_from_slice(args);
            print!("{} ", self.cyan("+")); print_args(&all); process::exit(0);
        }
        if self.options.verbose { let mut all = vec![program.into()]; all.extend_from_slice(args); print!("  "); print_args(&all); }
        let status = Command::new(program).args(args).status().unwrap_or_else(|error| self.fail(format!("could not run {program}: {error}")));
        process::exit(status.code().unwrap_or(1));
    }

    fn jump(&mut self, args: &[OsString]) {
        let pick = args.len() == 1 && args[0] == "--pick";
        if args.len() > 1 || (args.len() == 1 && !pick) { self.fail("usage: kuro jump [GENERATION|--pick]"); }
        let profile = home_profile_path();
        if profile.symlink_metadata().is_err() { self.fail(format!("no Home Manager generation profile found at {}", profile.display())); }
        let (generation, label) = if pick {
            let output = self.capture(&os_args(&["nix-env", "--profile", &profile.to_string_lossy(), "--list-generations"]));
            if !output.status.success() { io::stderr().write_all(&output.stderr).ok(); process::exit(output.status.code().unwrap_or(1)); }
            let generations = String::from_utf8_lossy(&output.stdout);
            let fzf = find_executable("fzf").unwrap_or_else(|| self.fail("fzf is required for 'kuro jump --pick'"));
            println!("\n{}", self.bright_cyan("pick a Home Manager generation"));
            let mut picker = Command::new(fzf).args(["--height=50%", "--layout=reverse", "--border", "--info=inline", "--pointer=▌", "--prompt=home › ", "--header=Choose a generation · Enter to switch · Esc to cancel"]).stdin(Stdio::piped()).stdout(Stdio::piped()).spawn().unwrap_or_else(|error| self.fail(format!("could not start fzf: {error}")));
            if let Some(mut input) = picker.stdin.take() { let _ = input.write_all(generations.as_bytes()); }
            let selected = picker.wait_with_output().unwrap_or_else(|error| self.fail(format!("fzf failed: {error}")));
            println!("{}", self.dim("selection complete"));
            if !selected.status.success() { return; }
            let line = String::from_utf8_lossy(&selected.stdout).trim().to_string();
            let gen = line.split_whitespace().next().unwrap_or("").to_string();
            let label = if gen.is_empty() { "no generation selected".into() } else { format!("generation {gen} (picked)") };
            (gen, label)
        } else if let Some(number) = args.first() {
            let gen = number.to_string_lossy().into_owned();
            let label = format!("generation {gen}");
            (gen, label)
        } else {
            (String::new(), "last known good generation (rollback)".into())
        };
        if !generation.is_empty() && generation.parse::<u32>().map(|n| n > 0).unwrap_or(false) == false { self.fail("generation must be a positive number"); }
        self.header("jump", &label);
        let mut switch: Vec<OsString> = os_args(&["nix-env", "--profile", &profile.to_string_lossy()]);
        if generation.is_empty() { switch.push("--rollback".into()); }
        else { switch.extend(["--switch-generation".into(), generation.into()]); }
        if self.options.dry_run {
            self.run(&switch);
            println!("+ {}/activate", profile.display());
            return;
        }
        let switched = self.run_task(&switch, "Generation switch");
        if !switched.success { process::exit(switched.code); }
        let activate = profile.join("activate");
        if !activate.is_file() { self.fail("Home Manager activation script is missing"); }
        let activated = self.run_task(&[activate.into_os_string()], "Home activation");
        if !activated.success { process::exit(activated.code); }
    }

    fn menu(&mut self) {
        let fzf = find_executable("fzf").unwrap_or_else(|| self.fail("fzf is required for the interactive menu"));
        let flake = self.options.flake_override.as_ref()
            .map(|path| shorten_home(&absolute_path(path)))
            .or_else(|| find_flake().map(|path| shorten_home(&path)))
            .unwrap_or_else(|| "not found · use --flake PATH".into());
        println!();
        println!("  {}", self.bright_cyan("KURO  /  SYSTEM WORKSPACE"));
        println!("  {}  {}", self.dim("profile  "), self.bright_cyan(&self.options.profile));
        println!("  {}  {}", self.dim("flake    "), self.dim(&flake));
                println!("  {}", self.dim("  ↑↓ navigate   type to filter   enter select   esc quit"));
        println!();
        let entries = [
            "sync\tSYSTEM    ·  Rebuild and switch this session",
            "boot\tSYSTEM    ·  Build and select for next boot",
            "test\tSYSTEM    ·  Try the configuration until reboot",
            "build\tSYSTEM    ·  Build without activating",
            "home\tDESKTOP   ·  Apply shell and user configuration",
            "status\tINSPECT   ·  View active system and generations",
            "doctor\tINSPECT   ·  Check flake and required tools",
            "jump --pick\tRECOVERY  ·  Choose a previous generation",
            "update\tMAINTAIN  ·  Refresh flake inputs",
            "clean\tMAINTAIN  ·  Remove old generations",
            "help\tREFERENCE ·  Browse all commands and examples",
        ];
        let mut picker = Command::new(fzf).args([
            "--height=65%", "--layout=reverse", "--border=rounded", "--info=inline",
            "--pointer=▌", "--marker=●", "--prompt=kuro › ",
            "--header=Choose an action", "--with-nth=1,2", "--delimiter=\t", "--no-sort",
            "--color=fg:#cdd6f4,bg:-1,hl:#89b4fa,fg+:#f5e0dc,bg+:#313244,hl+:#89b4fa,prompt:#cba6f7,pointer:#89b4fa,marker:#a6e3a1,info:#a6adc8,header:#a6adc8,border:#45475a",
        ]).stdin(Stdio::piped()).stdout(Stdio::piped()).spawn()
            .unwrap_or_else(|error| self.fail(format!("could not start fzf: {error}")));
        if let Some(mut input) = picker.stdin.take() { let _ = input.write_all(entries.join("\n").as_bytes()); }
        let output = picker.wait_with_output().unwrap_or_else(|error| self.fail(format!("fzf failed: {error}")));
        if !output.status.success() { return; }
        let selected = String::from_utf8_lossy(&output.stdout);
        let command = selected.split('\t').next().unwrap_or("").trim();
        let mut parts = command.split_whitespace();
        if let Some(name) = parts.next() { let args: Vec<OsString> = parts.map(Into::into).collect(); self.execute(name, &args); }
    }

    fn print_completion(&self, shell: &str) {
        let file = match shell { "zsh" => "_kuro", "fish" => "kuro.fish", _ => self.fail("usage: kuro completions zsh|fish") };
        let content = match file {
            "_kuro" => include_str!("../completions/_kuro"),
            _ => include_str!("../completions/kuro.fish"),
        };
        print!("{content}");
    }

    fn print_help(&self) {
        if !self.color { print!("{HELP}"); return; }
        for (index, line) in HELP.lines().enumerate() {
            if index == 0 { println!("{}", self.bright_cyan(line)); continue; }
            if line.is_empty() { println!(); continue; }
            if line.ends_with(':') && !line.starts_with("  ") { println!("{}", self.magenta(line)); continue; }
            if line.starts_with("  -") || line.starts_with("  !") { println!("{}", self.yellow(line)); continue; }
            if line.starts_with("  ") {
                let trimmed = line.trim_start();
                let split = trimmed.find(char::is_whitespace).unwrap_or(trimmed.len());
                let (command, rest) = trimmed.split_at(split);
                println!("  {}  {}", self.bright_cyan(command), self.dim(rest.trim_start()));
                continue;
            }
            println!("{}", self.dim(line));
        }
    }
}

// ── live output box ────────────────────────────────────────────────────────

struct TaskResult {
    success: bool,
    code: i32,
    stdout: String,
}

struct OutputLine {
    stdout: bool,
    text: String,
}

// Stream child output and show a bar only when Nix reports a work plan.
struct OutputBox {
    color: bool,
    interactive: bool,
    started: Instant,
    total: usize,
    completed: usize,
}

impl OutputBox {
    fn new(color: bool, label: &str) -> Self {
        println!();
        let title = if color { format!("\x1b[1;38;5;117mKuro\x1b[0m · {}", label) } else { format!("Kuro · {}", label) };
        println!("  {title}");
        Self { color, interactive: io::stdout().is_terminal(), started: Instant::now(), total: 0, completed: 0 }
    }

    fn paint(&self, code: &str, text: &str) -> String {
        if self.color { format!("\x1b[{code}m{text}\x1b[0m") } else { text.to_string() }
    }

    fn update_plan(&mut self, text: &str) {
        if !text.contains("will be built") && !text.contains("will be fetched") { return; }
        if let Some(count) = text.split_whitespace().nth(1).and_then(|value| value.parse::<usize>().ok()) {
            self.total = self.total.saturating_add(count);
        }
    }

    fn is_work_event(text: &str) -> bool {
        text.contains("building '/nix/store/") || text.contains("copying path '/nix/store/")
    }

    fn draw_progress(&self) {
        if !self.interactive || self.total == 0 { return; }
        let width = 24usize;
        let filled = self.completed.saturating_mul(width) / self.total;
        let bar = format!("{}{}", "█".repeat(filled), "░".repeat(width - filled));
        let pct = self.completed.saturating_mul(100) / self.total;
        print!("\r\x1b[2K  {}  {}  {}/{}  {}%",
            self.paint("38;5;176", &bar), self.paint("38;5;244", "Nix actions"),
            self.completed, self.total, pct);
        let _ = io::stdout().flush();
    }

    fn clear_progress(&self) {
        if self.interactive && self.total > 0 {
            print!("\r\x1b[2K");
            let _ = io::stdout().flush();
        }
    }

    fn line(&mut self, text: &str, is_stdout: bool) {
        self.update_plan(text);
        let work_event = Self::is_work_event(text);
        self.clear_progress();
        let line = if is_stdout { text.to_string() } else { self.paint("38;5;179", text) };
        println!("  · {line}");
        if work_event && self.total > 0 { self.completed = (self.completed + 1).min(self.total); }
        self.draw_progress();
    }

    fn finish(mut self, success: bool, message: &str) {
        let seconds = self.started.elapsed().as_secs();
        if success && self.total > 0 { self.completed = self.total; }
        self.clear_progress();
        if self.total > 0 { self.draw_progress(); println!(); }
        let icon = if success { self.paint("38;5;114", "✓") } else { self.paint("38;5;167", "✗") };
        let text = if success { self.paint("1;38;5;117", message) } else { self.paint("1;38;5;167", message) };
        println!("  {icon} {text}  {}", self.paint("38;5;244", &format!("({}s)", seconds)));
        println!();
    }
}

fn shorten_home(path: &Path) -> String {
    if let Some(home) = env::var_os("HOME") {
        if let Ok(rest) = path.strip_prefix(home) {
            return format!("~/{}", rest.display());
        }
    }
    path.display().to_string()
}

fn format_duration(seconds: u64) -> String {
    if seconds < 60 { format!("{seconds}s") }
    else { format!("{}m {:02}s", seconds / 60, seconds % 60) }
}

fn main() {
    let mut app = App::new();
    let mut args: Vec<OsString> = env::args_os().skip(1).collect();
    let index = 0;
    while index < args.len() {
        let token = args[index].to_string_lossy().into_owned();
        match token.as_str() {
            "-!" | "-n" | "--dry-run" => { app.options.dry_run = true; args.remove(index); }
            "-v" | "--verbose" => { app.options.verbose = true; args.remove(index); }
            "--no-color" => { app.options.no_color = true; app.color = false; args.remove(index); }
            "-f" | "--flake" | "-p" | "--profile" => {
                if index + 1 >= args.len() { app.fail(format!("option {token} requires a value")); }
                let value = PathBuf::from(&args[index + 1]);
                if token == "-f" || token == "--flake" { app.options.flake_override = Some(value); }
                else { app.options.profile = value.to_string_lossy().into_owned(); }
                args.drain(index..=index + 1);
            }
            "-h" | "--help" => { app.print_help(); return; }
            "--" => { args.remove(index); break; }
            value if value.starts_with('-') => app.fail(format!("unknown option '{value}' (run 'kuro --help')")),
            _ => break,
        }
    }
    if args.is_empty() && io::stdin().is_terminal() && io::stdout().is_terminal() { app.menu(); return; }
    let command = args.first().and_then(|arg| arg.to_str()).unwrap_or("help").to_string();
    if !args.is_empty() { args.remove(0); }
    let no_flake = matches!(command.as_str(), "try" | "run" | "search" | "fhs" | "profile" | "pr" | "status" | "generations" | "jump" | "clean" | "system" | "gc" | "help" | "h" | "menu" | "completions");
    if !no_flake && command != "path" { app.require_flake(); }
    app.execute(&command, &args);
}

fn parse_clean_args<'a>(app: &App, args: &'a [OsString], usage: &str) -> (bool, Option<&'a str>) {
    let mut system = false;
    let mut keep = None;
    let mut index = 0;
    while index < args.len() {
        match args[index].to_str() {
            Some("--system") if !system => { system = true; index += 1; }
            Some("--keep") if keep.is_none() && index + 1 < args.len() => {
                keep = args[index + 1].to_str();
                if keep.is_none() { app.fail("--keep requires a positive generation count"); }
                index += 2;
            }
            _ => app.fail(format!("usage: {usage}")),
        }
    }
    (system, keep)
}

fn absolute_path(path: &Path) -> PathBuf {
    if path.is_absolute() { path.to_path_buf() } else { env::current_dir().unwrap_or_else(|_| PathBuf::from("." )).join(path) }
}

fn find_flake() -> Option<PathBuf> {
    let mut dir = env::current_dir().ok()?;
    loop {
        if dir.join("flake.nix").is_file() { return Some(dir); }
        let nested = dir.join("root");
        if nested.join("flake.nix").is_file() { return Some(nested); }
        if !dir.pop() { break; }
    }
    let system = PathBuf::from("/etc/nixos");
    if system.join("flake.nix").is_file() { Some(system) } else { None }
}

fn home_profile_path() -> PathBuf {
    let state = env::var_os("XDG_STATE_HOME").map(PathBuf::from).unwrap_or_else(|| PathBuf::from(env::var_os("HOME").unwrap_or_else(|| ".".into())).join(".local/state"));
    state.join("nix/profiles/home-manager")
}

fn find_executable(name: &str) -> Option<PathBuf> {
    let path = env::var_os("PATH")?;
    env::split_paths(&path).map(|dir| dir.join(name)).find(|candidate| candidate.is_file())
}

fn os_args(values: &[&str]) -> Vec<OsString> { values.iter().map(OsString::from).collect() }

fn print_args(args: &[OsString]) {
    println!("{}", command_string(args));
}

fn command_string(args: &[OsString]) -> String {
    args.iter()
        .map(|arg| {
            let text = arg.to_string_lossy();
            if text.chars().all(|c| c.is_ascii_alphanumeric() || "_./:#-+".contains(c)) {
                text.into_owned()
            } else {
                format!("'{}'", text.replace('\'', "'\\''"))
            }
        })
        .collect::<Vec<_>>()
        .join(" ")
}
