module Compendium
  class ReportsController < ::ApplicationController
    helper Compendium::ReportsHelper
    include Compendium::ReportsHelper

    before_filter :find_report
    before_filter :validate_options, only: :run
    before_filter :run_report, only: :run

    def setup
      render_setup
    end

    def run
      template = template_exists?(@prefix, get_template_prefixes) ? @prefix : 'run'
      render action: template, locals: { report: @report }
    end

  private

    def find_report
      @prefix = params[:report_name]
      @report_name = "#{@prefix}_report"

      begin
        require(@report_name) unless Rails.env.development? or Module.const_defined?(@report_name.classify)
        @report_class = @report_name.camelize.constantize
        @report = setup_report
      rescue LoadError
        flash[:error] = t(:invalid_report)
        redirect_to action: :index
      end
    end

    def render_setup(opts = {})
      locals = { report: @report, prefix: @prefix }
      opts.empty? ? render(action: :setup, locals: locals) : render_if_exists(opts.merge(locals: locals)) || render(action: :setup, locals: locals)
    end

    def setup_report
      @report_class.new(params[:report] || {})
    end

    def validate_options
      render_setup and return unless @report.valid?
    end

    def run_report
      @report.run(self)
    end

    def get_template_prefixes
      paths = []
      klass = self.class

      begin
        paths << klass.name.underscore.gsub(/_controller$/, '')
        klass = klass.superclass
      end while(klass != ActionController::Base)

      paths
    end
  end
end