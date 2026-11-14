use std::env;
use std::ffi::OsString;
use std::fs;
use std::io::{self, IsTerminal, Read, Write};
use std::path::{Path, PathBuf};
use std::process::{self, Command, Output, Stdio};

const HELP: &str = r#"mono — Mono system and desktop manager

Usage: mono [OPTIONS] COMMAND [ARGS...]

Global options:
  -!, -n, --dry-run     Print commands without running them
  -f, --flake PATH      Use a specific flake directory
  -p, --profile NAME    Select a system profile (default: MONO_PROFILE or athena)
  -v, --verbose         Show commands as they run
  --no-color            Disable colored output
  -h, --help            Show this help

Build and activate:
  sync, switch, s [PROFILE]  Build and activate the system and Home Manager
  home [PROFILE]             Build and activate Home Manager only
  build, b [PROFILE]         Build without activating
  test [PROFILE]             Activate temporarily until reboot
  boot [PROFILE]             Activate on next boot
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
  style [NAME]               Show or switch the Home Manager color style
  clean [--system] [--keep COUNT]
                             Clean old Home Manager generations, or system with --system
  gc [--system]              Collect unreachable store paths
  shell status|restart|logs  Inspect or restart Monolix, or view its logs
  edit [FILE]                Open the flake or a file in it with $EDITOR
  menu                       Pick a mono command with fzf

Temporary packages:
  search QUERY               Search Nixpkgs for a package
  run PACKAGE [ARGS...]      Run a package once without installing it
  try PACKAGE...             Open a temporary shell with packages
  fhs [COMMAND...]           Open an FHS shell or run a command inside it

Environment:
  MONO_FLAKE      Flake directory (auto-detected when unset)
  MONO_PROFILE    Default profile (athena or athena-xmonad)
  MONO_USER       Home Manager username (default: atharva)

Examples:
  mono update
  mono sync
  mono --profile athena-xmonad test
  mono --dry-run home
  mono status
  mono style
  mono clean --keep 5
  mono search fastfetch
  mono run hello --greeting hi
  mono try ripgrep fd
  mono fhs ./some-linux-installer
  mono jump --pick
  mono shell logs

Profiles: athena (Niri + Monolix), athena-xmonad (XMonad)
Styles: jellybeans, aofuji, nothing, oled, yoru
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
            profile: env::var("MONO_PROFILE").or_else(|_| env::var("ATHENA_PROFILE")).unwrap_or_else(|_| "athena".into()),
            user: env::var("MONO_USER").or_else(|_| env::var("ATHENA_USER")).unwrap_or_else(|_| "atharva".into()),
            flake_override: env::var_os("MONO_FLAKE").or_else(|| env::var_os("ATHENA_FLAKE")).map(PathBuf::from),
            ..Options::default()
        };
        let color = io::stdout().is_terminal()
            && env::var_os("NO_COLOR").is_none()
            && env::var_os("TERM").as_deref() != Some(std::ffi::OsStr::new("dumb"));
        Self { options, flake: None, color }
    }

    fn fail(&self, message: impl AsRef<str>) -> ! {
        eprintln!("mono: {}", message.as_ref());
        process::exit(2)
    }

    fn styled(&self, code: &str, text: &str) -> String {
        if self.color { format!("\x1b[{code}m{text}\x1b[0m") } else { text.to_string() }
    }

    fn say(&self, text: &str) { println!("{} {text}", self.styled("34", "mono")); }
    fn ok(&self, text: &str) { println!("{} {text}", self.styled("32", "✓")); }
    fn warn(&self, text: &str) { eprintln!("{} {text}", self.styled("33", "!")); }

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
        if profile != "athena" && profile != "athena-xmonad" {
            self.fail(format!("unknown profile '{profile}' (choose athena or athena-xmonad)"));
        }
    }

    fn flake_ref(&mut self) -> String { format!("path:{}", self.require_flake().display()) }

    fn command(&self, args: &[OsString]) -> ! {
        if args.is_empty() { self.fail("internal error: empty command"); }
        if self.options.dry_run {
            print!("{} ", self.styled("34", "+"));
            print_args(args);
            process::exit(0);
        }
        if self.options.verbose {
            print!("  ");
            print_args(args);
        }
        let status = Command::new(&args[0]).args(&args[1..]).status()
            .unwrap_or_else(|error| self.fail(format!("could not run {:?}: {error}", args[0])));
        process::exit(status.code().unwrap_or(1));
    }

    fn capture(&self, args: &[OsString]) -> Output {
        Command::new(&args[0]).args(&args[1..]).output()
            .unwrap_or_else(|error| self.fail(format!("could not run {:?}: {error}", args[0])))
    }

    fn stream_and_capture_stdout(&self, args: &[OsString]) -> Output {
        let mut child = Command::new(&args[0])
            .args(&args[1..])
            .stdout(Stdio::piped())
            .stderr(Stdio::inherit())
            .spawn()
            .unwrap_or_else(|error| self.fail(format!("could not run {:?}: {error}", args[0])))
        ;
        let mut stream = child.stdout.take().expect("piped child stdout");
        let mut captured = Vec::new();
        let mut buffer = [0_u8; 8192];
        let mut terminal = io::stdout().lock();
        loop {
            let count = stream.read(&mut buffer)
                .unwrap_or_else(|error| self.fail(format!("could not read {:?} output: {error}", args[0])));
            if count == 0 { break; }
            captured.extend_from_slice(&buffer[..count]);
            terminal.write_all(&buffer[..count])
                .and_then(|_| terminal.flush())
                .unwrap_or_else(|error| self.fail(format!("could not display command output: {error}")));
        }
        drop(terminal);
        let status = child.wait()
            .unwrap_or_else(|error| self.fail(format!("could not wait for {:?}: {error}", args[0])));
        Output { status, stdout: captured, stderr: Vec::new() }
    }

    fn generations(&self, target: &str) {
        let profile_path = match target {
            "home" => home_profile_path(),
            "system" => PathBuf::from("/nix/var/nix/profiles/system"),
            _ => self.fail(format!("unknown generation target '{target}' (choose system or home)")),
        };
        if target == "home" && !profile_path.exists() && !profile_path.symlink_metadata().is_ok() {
            self.warn(&format!("no Home Manager generations found at {}", profile_path.display()));
            return;
        }
        let mut args: Vec<OsString> = if target == "system" { vec!["sudo".into()] } else { vec![] };
        args.extend(["nix-env".into(), "--profile".into(), profile_path.into_os_string(), "--list-generations".into()]);
        self.run_checked(&args)
    }

    fn delete_generations(&self, target: &str, keep: Option<&str>) {
        if let Some(count) = keep {
            if count.parse::<u32>().map(|n| n > 0).unwrap_or(false) == false {
                self.fail("--keep requires a positive generation count");
            }
        }
        let generation_selector = keep.map(|count| format!("+{count}")).unwrap_or_else(|| "old".into());
        let (profile, privileged) = if target == "home" { (home_profile_path(), false) } else { (PathBuf::from("/nix/var/nix/profiles/system"), true) };
        if target == "home" && !profile.exists() && profile.symlink_metadata().is_err() && !self.options.dry_run {
            self.warn(&format!("no Home Manager generation profile found at {}", profile.display()));
            return;
        }
        let mut args: Vec<OsString> = if privileged { vec!["sudo".into()] } else { vec![] };
        args.extend(["nix-env".into(), "--profile".into(), profile.into_os_string(), "--delete-generations".into(), generation_selector.into()]);
        self.run(&args);
        let mut gc: Vec<OsString> = if privileged { vec!["sudo".into()] } else { vec![] };
        gc.extend(["nix-collect-garbage".into()]);
        self.run(&gc);
    }

    fn run(&self, args: &[OsString]) {
        if self.options.dry_run {
            print!("{} ", self.styled("34", "+"));
            print_args(args);
        } else {
            if self.options.verbose { print!("  "); print_args(args); }
            let status = Command::new(&args[0]).args(&args[1..]).status()
                .unwrap_or_else(|error| self.fail(format!("could not run {:?}: {error}", args[0])));
            if !status.success() { process::exit(status.code().unwrap_or(1)); }
        }
    }

    fn run_checked(&self, args: &[OsString]) {
        if self.options.dry_run { self.run(args); return; }
        if self.options.verbose { print!("  "); print_args(args); }
        let status = Command::new(&args[0]).args(&args[1..]).status()
            .unwrap_or_else(|error| self.fail(format!("could not run {:?}: {error}", args[0])));
        if !status.success() { process::exit(status.code().unwrap_or(1)); }
    }

    fn activate_hm_service(&self, profile: &str) {
        if profile != "athena" { return; }
        self.run(&os_args(&["systemctl", "--user", "daemon-reload"]));
        self.run(&os_args(&["systemctl", "--user", "try-restart", "monolix.service"]));
    }

    fn execute(&mut self, command: &str, args: &[OsString]) {
        match command {
            "help" | "h" => print!("{HELP}"),
            "menu" => self.menu(),
            "path" => println!("{}", self.require_flake().display()),
            "style" => self.style(args),
            "profile" | "pr" => println!("{}         Niri + Monolix\nathena-xmonad  XMonad", self.styled("1", "athena")),
            "info" => {
                let flake = self.require_flake();
                println!("{}  {}\n{}  {}\n{}     {}", self.styled("1", "Flake"), flake.display(), self.styled("1", "Profile"), self.options.profile, self.styled("1", "User"), self.options.user);
                self.command(&os_args(&["nix", "--version"]));
            }
            "doctor" => {
                self.profile(&self.options.profile);
                let flake = self.require_flake();
                self.say(&format!("Checking profile '{}' and flake at {}", self.options.profile, flake.display()));
                if flake.join("flake.nix").is_file() { self.ok("flake.nix found"); } else { self.fail("flake.nix is missing"); }
                if flake.join("flake.lock").is_file() { self.ok("flake.lock found"); } else { self.warn("flake.lock is missing; Nix will create it when needed"); }
                for tool in ["nix", "nixos-rebuild", "sudo"] {
                    match find_executable(tool) { Some(path) => self.ok(&format!("{tool}: {}", path.display())), None => self.warn(&format!("{tool} is not in PATH")) }
                }
                if self.options.profile == "athena" {
                    match find_executable("systemctl") { Some(_) => self.ok("systemctl available for Monolix service management"), None => self.warn("systemctl is not in PATH") }
                }
            }
            "status" => {
                self.profile(&self.options.profile);
                println!("{}", self.styled("1", "System generations")); self.generations("system");
                println!("\n{}", self.styled("1", "Home Manager generations")); self.generations("home");
                if self.options.profile == "athena" && find_executable("systemctl").is_some() {
                    println!("\n{}", self.styled("1", "Monolix service"));
                    let _ = Command::new("systemctl").args(["--user", "--no-pager", "status", "monolix"]).status();
                }
            }
            "generations" => {
                if args.len() > 1 { self.fail("usage: mono generations [system|home]"); }
                match args.first().and_then(|arg| arg.to_str()).unwrap_or("all") {
                    "all" => { println!("{}", self.styled("1", "System generations")); self.generations("system"); println!("\n{}", self.styled("1", "Home Manager generations")); self.generations("home"); }
                    target => self.generations(target),
                }
            }
            "pull" | "update" => {
                if args.len() > 1 { self.fail(format!("usage: mono {command} [INPUT]")); }
                self.say("Updating flake inputs and refreshing flake.lock...");
                let mut nix_args = os_args(&["nix", "flake", "update"]);
                if let Some(input) = args.first() { nix_args.push(input.clone()); }
                let flake_ref = self.flake_ref();
                nix_args.extend(["--flake".into(), flake_ref.into()]);
                self.command(&nix_args);
            }
            "check" => {
                if args.len() > 1 { self.fail("usage: mono check [PROFILE]"); }
                let target = args.first().and_then(|s| s.to_str()).unwrap_or(&self.options.profile).to_string();
                self.profile(&target);
                let flake_ref = self.flake_ref();
                self.command(&["nix".into(), "flake".into(), "check".into(), "--no-build".into(), "--show-trace".into(), flake_ref.into()]);
            }
            "gc" => {
                if args.is_empty() { self.run(&os_args(&["nix-collect-garbage"])); }
                else if args.len() == 1 && args[0] == "--system" { self.run(&os_args(&["sudo", "nix-collect-garbage"])); }
                else { self.fail("usage: mono gc [--system]"); }
            }
            "clean" => {
                let (system, keep) = parse_clean_args(self, args, "mono clean [--system] [--keep COUNT]");
                self.delete_generations(if system { "system" } else { "home" }, keep);
            }
            "system" => {
                if args.first().and_then(|s| s.to_str()) != Some("clean") { self.fail("usage: mono system clean [--keep COUNT]"); }
                let (_, keep) = parse_clean_args(self, &args[1..], "mono system clean [--keep COUNT]");
                self.delete_generations("system", keep);
            }
            "sync" | "switch" | "s" | "build" | "b" | "test" | "boot" => {
                if args.len() > 1 { self.fail(format!("usage: mono {command} [PROFILE]")); }
                let target = args.first().and_then(|s| s.to_str()).unwrap_or(&self.options.profile).to_string();
                self.profile(&target);
                let action = match command { "sync" | "switch" | "s" => "switch", "build" | "b" => "build", "test" => "test", _ => "boot" };
                let flake_ref = self.flake_ref();
                self.command(&["sudo".into(), "nixos-rebuild".into(), action.into(), "--flake".into(), format!("{flake_ref}#{target}").into()]);
            }
            "home" => {
                if args.len() > 1 { self.fail("usage: mono home [PROFILE]"); }
                let target = args.first().and_then(|s| s.to_str()).unwrap_or(&self.options.profile).to_string();
                self.profile(&target);
                let attr = format!("nixosConfigurations.{target}.config.home-manager.users.{}.home.activationPackage", self.options.user);
                let flake_ref = self.flake_ref();
                let installable = format!("{flake_ref}#{attr}");
                let build = os_args(&["nix", "build", &installable, "--no-link", "--print-out-paths"]);
                if self.options.dry_run {
                    self.run(&build);
                    println!("+ activate the resulting Home Manager package as the current user");
                    if target == "athena" { println!("+ systemctl --user daemon-reload\n+ systemctl --user try-restart monolix.service"); }
                } else {
                    if self.options.verbose { print!("  "); print_args(&build); }
                    let output = self.stream_and_capture_stdout(&build);
                    if !output.status.success() { io::stderr().write_all(&output.stderr).ok(); process::exit(output.status.code().unwrap_or(1)); }
                    let activation = String::from_utf8_lossy(&output.stdout).trim().to_string();
                    let script = Path::new(&activation).join("activate");
                    if !script.is_file() { self.fail(format!("Home Manager activation script missing from {activation}")); }
                    self.run_checked(&[script.into_os_string()]);
                    if find_executable("systemctl").is_some() { self.activate_hm_service(&target); }
                }
            }
            "jump" => self.jump(args),
            "try" => {
                if args.is_empty() { self.fail("usage: mono try PACKAGE..."); }
                let mut nix_args = os_args(&["nix", "shell"]);
                for package in args { let package = package.to_string_lossy(); nix_args.push(if package.contains('#') { package.into_owned().into() } else { format!("nixpkgs#{package}").into() }); }
                self.command(&nix_args);
            }
            "run" => {
                if args.is_empty() { self.fail("usage: mono run PACKAGE [ARGS...]"); }
                let package = args[0].to_string_lossy();
                let mut nix_args = vec!["nix".into(), "run".into(), (if package.contains('#') { package.into_owned() } else { format!("nixpkgs#{package}") }).into(), "--".into()];
                nix_args.extend_from_slice(&args[1..]);
                self.command(&nix_args);
            }
            "search" => {
                if args.len() != 1 { self.fail("usage: mono search QUERY"); }
                self.command(&["nix".into(), "search".into(), "nixpkgs".into(), args[0].clone()]);
            }
            "fhs" => {
                let mut command = os_args(&["nix", "shell", "nixpkgs#steam-run", "--command", "steam-run"]);
                if args.is_empty() { command.extend(["zsh".into(), "-i".into()]); } else { command.extend_from_slice(args); }
                self.command(&command);
            }
            "shell" | "service" => self.shell(args),
            "edit" => {
                if args.len() > 1 { self.fail("usage: mono edit [FILE]"); }
                let editor = env::var("EDITOR").or_else(|_| env::var("VISUAL")).unwrap_or_else(|_| "nano".into());
                let target = args.first().and_then(|s| s.to_str()).unwrap_or("flake.nix");
                let target = PathBuf::from(target);
                let target = if target.is_absolute() { target } else { self.require_flake().join(target) };
                if !target.exists() { self.fail(format!("file not found: {}", target.display())); }
                let mut editor_parts = editor.split_whitespace();
                let editor_bin = editor_parts.next().unwrap_or("nano");
                let mut editor_args: Vec<OsString> = editor_parts.map(Into::into).collect(); editor_args.push(target.into_os_string());
                self.command_with(editor_bin, &editor_args);
            }
            "completions" => {
                if args.len() != 1 { self.fail("usage: mono completions zsh|fish"); }
                self.print_completion(args[0].to_string_lossy().as_ref());
            }
            _ => self.fail(format!("unknown command '{command}' (run 'mono help')")),
        }
    }

    fn command_with(&self, program: &str, args: &[OsString]) -> ! {
        if self.options.dry_run {
            let mut all = vec![program.into()]; all.extend_from_slice(args);
            print!("{} ", self.styled("34", "+")); print_args(&all); process::exit(0);
        }
        if self.options.verbose { let mut all = vec![program.into()]; all.extend_from_slice(args); print!("  "); print_args(&all); }
        let status = Command::new(program).args(args).status().unwrap_or_else(|error| self.fail(format!("could not run {program}: {error}")));
        process::exit(status.code().unwrap_or(1));
    }

    fn style(&mut self, args: &[OsString]) {
        const STYLES: [&str; 5] = ["jellybeans", "aofuji", "nothing", "oled", "yoru"];
        if args.len() > 1 { self.fail("usage: mono style [jellybeans|aofuji|nothing|oled|yoru]"); }

        let flake = self.require_flake();
        let style_file = flake.join("home/home-manager/style.nix");
        let current = fs::read_to_string(&style_file)
            .unwrap_or_else(|error| self.fail(format!("could not read {}: {error}", style_file.display())))
            .trim()
            .trim_matches('"')
            .to_string();
        if !STYLES.contains(&current.as_str()) {
            self.fail(format!("{} contains unknown style '{current}'", style_file.display()));
        }

        let selected = if let Some(style) = args.first() {
            style.to_string_lossy().into_owned()
        } else if io::stdin().is_terminal() && io::stdout().is_terminal() {
            let fzf = find_executable("fzf").unwrap_or_else(|| self.fail("fzf is required for the interactive style picker"));
            let options = STYLES.iter().map(|style| {
                if *style == current { format!("{style}\tcurrent") } else { format!("{style}\t") }
            }).collect::<Vec<_>>().join("\n");
            let mut picker = Command::new(fzf)
                .args(["--prompt=Mono style > ", "--height=40%", "--reverse", "--border", "--with-nth=1,2", "--delimiter=\t", "--header=Choose a Home Manager color style"])
                .stdin(Stdio::piped()).stdout(Stdio::piped()).spawn()
                .unwrap_or_else(|error| self.fail(format!("could not start fzf: {error}")));
            if let Some(mut input) = picker.stdin.take() { let _ = input.write_all(options.as_bytes()); }
            let output = picker.wait_with_output().unwrap_or_else(|error| self.fail(format!("fzf failed: {error}")));
            if !output.status.success() { return; }
            String::from_utf8_lossy(&output.stdout).split('\t').next().unwrap_or("").trim().to_string()
        } else {
            println!("Current style: {current}\nAvailable styles: {}", STYLES.join(", "));
            return;
        };

        if !STYLES.contains(&selected.as_str()) {
            self.fail(format!("unknown style '{selected}' (choose {})", STYLES.join(", ")));
        }
        if selected == current {
            self.ok(&format!("{selected} is already active"));
            return;
        }
        self.say(&format!("Switching Home Manager style from {current} to {selected}"));
        if self.options.dry_run {
            println!("{} write {} = \"{}\"", self.styled("34", "+"), style_file.display(), selected);
        } else {
            let temporary = style_file.with_extension("nix.tmp");
            fs::write(&temporary, format!("\"{selected}\"\n"))
                .unwrap_or_else(|error| self.fail(format!("could not write {}: {error}", temporary.display())));
            fs::rename(&temporary, &style_file)
                .unwrap_or_else(|error| self.fail(format!("could not update {}: {error}", style_file.display())));
        }
        self.execute("home", &[]);
    }

    fn jump(&mut self, args: &[OsString]) {
        let pick = args.len() == 1 && args[0] == "--pick";
        if args.len() > 1 || (args.len() == 1 && !pick) { self.fail("usage: mono jump [GENERATION|--pick]"); }
        let profile = home_profile_path();
        if !profile.exists() && profile.symlink_metadata().is_err() { self.fail(format!("no Home Manager generation profile found at {}", profile.display())); }
        let generation = if pick {
            let output = self.capture(&os_args(&["nix-env", "--profile", &profile.to_string_lossy(), "--list-generations"]));
            if !output.status.success() { io::stderr().write_all(&output.stderr).ok(); process::exit(output.status.code().unwrap_or(1)); }
            let generations = String::from_utf8_lossy(&output.stdout);
            let fzf = find_executable("fzf").unwrap_or_else(|| self.fail("fzf is required for 'mono jump --pick'"));
            let mut picker = Command::new(fzf).args(["--prompt=Home generation > ", "--height=40%", "--reverse", "--border", "--header=Choose a Home Manager generation"]).stdin(Stdio::piped()).stdout(Stdio::piped()).spawn().unwrap_or_else(|error| self.fail(format!("could not start fzf: {error}")));
            if let Some(mut input) = picker.stdin.take() { let _ = input.write_all(generations.as_bytes()); }
            let selected = picker.wait_with_output().unwrap_or_else(|error| self.fail(format!("fzf failed: {error}")));
            if !selected.status.success() { return; }
            let line = String::from_utf8_lossy(&selected.stdout).trim().to_string();
            line.split_whitespace().next().unwrap_or("").to_string()
        } else if let Some(number) = args.first() { number.to_string_lossy().into_owned() } else { String::new() };
        if !generation.is_empty() && generation.parse::<u32>().map(|n| n > 0).unwrap_or(false) == false { self.fail("generation must be a positive number"); }
        if generation.is_empty() { self.run(&["nix-env".into(), "--profile".into(), profile.clone().into_os_string(), "--rollback".into()]); }
        else { self.run(&["nix-env".into(), "--profile".into(), profile.clone().into_os_string(), "--switch-generation".into(), generation.into()]); }
        if self.options.dry_run { println!("+ {}/activate", profile.display()); if self.options.profile == "athena" { println!("+ systemctl --user daemon-reload\n+ systemctl --user try-restart monolix.service"); } return; }
        let activate = profile.join("activate");
        if !activate.is_file() { self.fail("Home Manager activation script is missing"); }
        self.run_checked(&[activate.into_os_string()]);
        self.activate_hm_service(&self.options.profile);
    }

    fn shell(&self, args: &[OsString]) {
        if self.options.profile != "athena" { self.fail("Monolix service is available only in the athena profile"); }
        if find_executable("systemctl").is_none() { self.fail("systemctl is not available"); }
        match args.first().and_then(|s| s.to_str()).unwrap_or("status") {
            "status" if args.len() <= 1 => self.command(&os_args(&["systemctl", "--user", "--no-pager", "status", "monolix"])),
            "restart" if args.len() == 1 => { self.run(&os_args(&["systemctl", "--user", "daemon-reload"])); self.command(&os_args(&["systemctl", "--user", "restart", "monolix.service"])); }
            "logs" if args.len() <= 2 => match args.get(1).and_then(|s| s.to_str()) {
                None => self.command(&os_args(&["journalctl", "--user", "-u", "monolix.service", "-n", "80", "--no-pager"])),
                Some("--follow") | Some("-f") => self.command(&os_args(&["journalctl", "--user", "-u", "monolix.service", "-f"])),
                _ => self.fail("usage: mono shell logs [--follow]"),
            },
            _ => self.fail("usage: mono shell status|restart|logs [--follow]"),
        }
    }

    fn menu(&mut self) {
        let fzf = find_executable("fzf").unwrap_or_else(|| self.fail("fzf is required for the interactive menu"));
        let entries = ["sync\tBuild and activate system", "home\tBuild and activate Home Manager", "style\tChoose a Home Manager color style", "status\tShow system and home generations", "jump --pick\tChoose a Home Manager generation", "shell logs\tView Monolix logs", "doctor\tCheck the local setup", "help\tShow all commands"];
        let mut picker = Command::new(fzf).args(["--prompt=mono > ", "--height=50%", "--reverse", "--border", "--with-nth=1,2", "--delimiter=\t"]).stdin(Stdio::piped()).stdout(Stdio::piped()).spawn().unwrap_or_else(|error| self.fail(format!("could not start fzf: {error}")));
        if let Some(mut input) = picker.stdin.take() { let _ = input.write_all(entries.join("\n").as_bytes()); }
        let output = picker.wait_with_output().unwrap_or_else(|error| self.fail(format!("fzf failed: {error}")));
        if !output.status.success() { return; }
        let selected = String::from_utf8_lossy(&output.stdout);
        let command = selected.split('\t').next().unwrap_or("").trim();
        let mut parts = command.split_whitespace();
        if let Some(name) = parts.next() { let args: Vec<OsString> = parts.map(Into::into).collect(); self.execute(name, &args); }
    }

    fn print_completion(&self, shell: &str) {
        let file = match shell { "zsh" => "_mono", "fish" => "mono.fish", _ => self.fail("usage: mono completions zsh|fish") };
        let content = match file {
            "_mono" => include_str!("../completions/_mono"),
            _ => include_str!("../completions/mono.fish"),
        };
        print!("{content}");
    }
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
            "-h" | "--help" => { print!("{HELP}"); return; }
            "--" => { args.remove(index); break; }
            value if value.starts_with('-') => app.fail(format!("unknown option '{value}' (run 'mono --help')")),
            _ => break,
        }
    }
    if args.is_empty() && io::stdin().is_terminal() && io::stdout().is_terminal() { app.menu(); return; }
    let command = args.first().and_then(|arg| arg.to_str()).unwrap_or("help").to_string();
    if !args.is_empty() { args.remove(0); }
    let no_flake = matches!(command.as_str(), "try" | "run" | "search" | "fhs" | "shell" | "service" | "profile" | "pr" | "status" | "generations" | "jump" | "clean" | "system" | "gc" | "help" | "h" | "menu" | "completions");
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
    for arg in args {
        let text = arg.to_string_lossy();
        if text.chars().all(|c| c.is_ascii_alphanumeric() || "_./:#-+".contains(c)) { print!("{text} "); }
        else { print!("'{}' ", text.replace('\'', "'\\''")); }
    }
    println!();
}
