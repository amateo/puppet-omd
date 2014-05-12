# == Class omd::config
#
# This class is called from omd
#
class omd::config {
  Mount <| tag == 'omd::site' |>
  Exec <| tag == 'omd::site' |>
}
