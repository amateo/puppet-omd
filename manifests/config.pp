# == Class omd::config
#
# This class is called from omd
#
class omd::config {
  Mount <| tag == 'omd::site::config' |>
  Exec <| tag == 'omd::site::config' |>
  File <| tag == 'omd::site::config' |>
}
