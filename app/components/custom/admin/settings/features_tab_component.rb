load Rails.root.join("app","components","admin","settings","features_tab_component.rb")

class Admin::Settings::FeaturesTabComponent < ApplicationComponent
  def settings
    %w[
      feature.featured_proposals
      feature.facebook_login
      feature.google_login
      feature.twitter_login
      feature.wordpress_login
      feature.saml_login
      feature.signature_sheets
      feature.user.recommendations
      feature.user.recommendations_on_debates
      feature.user.recommendations_on_proposals
      feature.user.skip_verification
      feature.community
      feature.map
      feature.allow_attached_documents
      feature.allow_images
      feature.help_page
      feature.remote_translations
      feature.translation_interface
      feature.remote_census
      feature.valuation_comment_notification
      feature.graphql_api
      feature.sdg
      feature.machine_learning
      feature.remove_investments_supports
      feature.dashboard.notification_emails
    ]
  end
end
