# System and File Operation Commands
#
# Auto-approved commands for file operations, modern CLI tools, system info, network.
# Imported by allow.nix - do not use directly.

_:

{
  # --- File Operations ---
  fileRead = [
    "ls"
    "cat"
    "head"
    "tail"
    "less"
    "more"
    "wc"
    "grep"
    "find"
    "tree"
    "pwd"
    "cd"
    "diff"
    "cut"
    "sort"
    "uniq"
    "jq"
    "yq"
    "file"
    "readlink"
    "sed"
    "awk"
  ];

  fileCreate = [
    "mkdir"
    "touch"
    "ln"
    "ln -s"
    "ln -sf"
  ];

  archive = [
    "tar -tzf"
    "tar -xzf"
    "tar -czf"
    "tar --disable-copyfile"
    "zip"
    "unzip"
    "gzip"
    "gunzip"
  ];

  # --- Modern CLI Tools ---
  modernCli = [
    "bat"
    "delta"
    "eza"
    "fd"
    "fzf"
    "htop"
    "ncdu"
    "tldr"
    "rg"
  ];

  # --- System Information ---
  system = [
    "whoami"
    "hostname"
    "uname"
    "date"
    "uptime"
    "which"
    "whereis"
    "ps"
    "top -l 1"
    "df"
    "du"
    "free"
    "env"
    "printenv"
    "type"
    "time"
    "timeout"
    "hash"
  ];

  macos = [
    "sw_vers"
    "mdls"
    "mdfind"
    "launchctl list"
    "launchctl print"
    "pbcopy"
    "pbpaste"
  ];

  shell = [
    "echo"
    "printf"
    "test"
    "export"
    "alias"
    "history"
    "sleep"
    "true"
    "false"
    "source"
  ];

  # --- Network ---
  network = [
    "curl -s -X GET"
    "curl -s --request GET"
    "curl --silent -X GET"
    "curl --silent --request GET"
    "curl -X GET"
    "curl --request GET"
    "ping -c"
    "nslookup"
    "dig"
    "host"
    "netstat"
    "lsof -i"
    "wget"
  ];
}
