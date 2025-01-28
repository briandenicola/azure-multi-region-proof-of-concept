locals {
  global_rg_name    = "${var.app_name}_global_rg"
  acr_name          = "${replace(var.app_name, "-", "")}acr"
}