path "secret/*" {
  capabilities = ["read", "list"]
}
path "secret/data/*" {
  capabilities = ["read", "list"]
}
path "secret/metadata/*" {
  capabilities = ["read", "list"]
}
path "sys/internal/ui/mounts/*" {
  capabilities = ["read"]
}
