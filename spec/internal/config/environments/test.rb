require File.expand_path('../../../config/hosts', __FILE__)

Rails.application.config.cache_store = :memory_store

Rails.application.config.i18n.enforce_available_locales = false
Rails.application.config.i18n.default_locale = :ru
Rails.application.config.i18n.locale = :ru
