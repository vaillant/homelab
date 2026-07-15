output "nix_builder_hostname" {
  description = "Hostname of the nix-builder container"
  value       = module.nix_builder.hostname
}
