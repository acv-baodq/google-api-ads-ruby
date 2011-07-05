#!/usr/bin/ruby
#
# Authors:: api.dklimkin@gmail.com (Danial Klimkin)
#
# Copyright:: Copyright 2011, Google Inc. All Rights Reserved.
#
# License:: Licensed under the Apache License, Version 2.0 (the "License");
#           you may not use this file except in compliance with the License.
#           You may obtain a copy of the License at
#
#           http://www.apache.org/licenses/LICENSE-2.0
#
#           Unless required by applicable law or agreed to in writing, software
#           distributed under the License is distributed on an "AS IS" BASIS,
#           WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
#           implied.
#           See the License for the specific language governing permissions and
#           limitations under the License.
#
# Contains the main classes for the client library. Takes care of all
# dependencies.

gem 'google-ads-common', '~>0.5.0'
require 'logger'
require 'ads_common/api'
require 'ads_common/config'
require 'ads_common/auth/client_login_handler'
require 'ads_common/savon_headers/client_login_header_handler'
require 'ads_common/savon_headers/oauth_header_handler'
require 'ads_common/savon_headers/simple_header_handler'
require 'dfp_api/errors'
require 'dfp_api/api_config'
require 'dfp_api/extensions'
require 'dfp_api/credential_handler'

# Main namespace for all the client library's modules and classes.
module DfpApi

  # Wrapper class that serves as the main point of access for all the API usage.
  #
  # Holds all the services, as well as login credentials.
  #
  class Api < AdsCommon::Api
    # Constructor for API.
    def initialize(provided_config = nil)
      super(provided_config)
      @credential_handler = DfpApi::CredentialHandler.new(@config)
    end

    # Sets the logger to use.
    def logger=(logger)
      super(logger)
      Savon.configure do |config|
        config.log_level = :debug
        config.logger = logger
      end
    end

    # Getter for the API service configurations.
    def api_config
      DfpApi::ApiConfig
    end

    private

    # Retrieve DFP HeaderHandlers per credential.
    def soap_header_handlers(auth_handler, header_list, version)
      handler = nil
      auth_method = @config.read('authentication.method',
          'ClientLogin').to_s.upcase.to_sym
      handler = case auth_method
        when :CLIENTLOGIN
          (version == :v201101) ?
              AdsCommon::SavonHeaders::SimpleHeaderHandler :
              AdsCommon::SavonHeaders::ClientLoginHeaderHandler
        when :OAUTH
          AdsCommon::SavonHeaders::OAuthHeaderHandler
      end
      ns = api_config.headers_config[:HEADER_NAMESPACE_PREAMBLE] + version.to_s
      return [handler.new(@credential_handler, auth_handler,
          api_config.headers_config[:REQUEST_HEADER], ns, version)]
    end

    # Handle loading of a single service wrapper. Needs to be implemented on
    # specific API level.
    #
    # Args:
    # - version: intended API version. Must be a symbol.
    # - service: name for the intended service. Must be a symbol.
    #
    # Returns:
    # - a wrapper generated for the service.
    #
    def prepare_wrapper(version, service)
      environment = config.read('service.environment')
      api_config.do_require(version, service)
      endpoint = api_config.endpoint(environment, version, service)
      interface_class_name = api_config.interface_name(version, service)
      endpoint_url = endpoint.nil? ? nil : endpoint.to_s + service.to_s
      wrapper = class_for_path(interface_class_name).new(endpoint_url)

      auth_handler = get_auth_handler(environment)
      header_list =
          auth_handler.header_list(@credential_handler.credentials(version))

      soap_handlers = soap_header_handlers(auth_handler, header_list, version)
      soap_handlers.each do |handler|
        wrapper.headerhandler << handler
      end

      return wrapper
    end

    # Converts complete class path into class object.
    def class_for_path(path)
      path.split('::').inject(Kernel) do |scope, const_name|
        scope.const_get(const_name)
      end
    end
  end
end
