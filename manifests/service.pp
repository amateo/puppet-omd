# == Class omd::service
#
# This class is meant to be called from omd
# It ensure the service is running
#
class omd::service {
  Service <| tag == 'omd::site::service' |>
}
