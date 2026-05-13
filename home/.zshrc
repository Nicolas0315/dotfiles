# Shared zsh entrypoint. Keep behavior in focused fragments.
for file in "$HOME/.paths" "$HOME/.exports" "$HOME/.functions" "$HOME/.aliases" "$HOME/.tooling"; do
  [ -f "$file" ] && source "$file"
done
unset file
