# Encoding: utf-8
#
# This is auto-generated code, changes will be overwritten.
#
# Copyright:: Copyright 2013, Google Inc. All Rights Reserved.
# License:: Licensed under the Apache License, Version 2.0.
#
# Code generated by AdsCommon library 0.9.5 on 2015-02-11 12:50:56.

require 'ads_common/savon_service'
require 'dfp_api/v201502/team_service_registry'

module DfpApi; module V201502; module TeamService
  class TeamService < AdsCommon::SavonService
    def initialize(config, endpoint)
      namespace = 'https://www.google.com/apis/ads/publisher/v201502'
      super(config, endpoint, namespace, :v201502)
    end

    def create_teams(*args, &block)
      return execute_action('create_teams', args, &block)
    end

    def get_teams_by_statement(*args, &block)
      return execute_action('get_teams_by_statement', args, &block)
    end

    def update_teams(*args, &block)
      return execute_action('update_teams', args, &block)
    end

    private

    def get_service_registry()
      return TeamServiceRegistry
    end

    def get_module()
      return DfpApi::V201502::TeamService
    end
  end
end; end; end