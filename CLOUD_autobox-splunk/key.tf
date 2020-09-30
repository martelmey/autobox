resource "aws_key_pair" "autobox-key" {
  key_name   = "autobox-key"
  public_key = file(var.PATH_TO_PUBLIC_KEY)
}