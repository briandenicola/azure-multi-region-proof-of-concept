locals {
  global_rg_name = "${var.app_name}_global_rg"
   authorized_ip_ranges = "${chomp(data.http.myip.response_body)}/32"
}
