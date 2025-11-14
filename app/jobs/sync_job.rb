class SyncJob < ApplicationJob
  queue_as :high_priority

  # Can be called with a specific sync, or without parameters to sync all families
  def perform(sync = nil)
    if sync
      # Single sync - used when triggered manually or by user action
      sync.perform
    else
      # Bulk sync - used by cron job to sync all families with provider items
      sync_all_families
    end
  end

  private

  def sync_all_families
    Family.find_each do |family|
      # Only sync families that have configured provider items or accounts
      next unless family_has_syncable_items?(family)

      Rails.logger.info("Scheduled sync for family #{family.id}")
      family.sync_later
    rescue => e
      Rails.logger.error("Failed to schedule sync for family #{family.id}: #{e.message}")
      Sentry.capture_exception(e) do |scope|
        scope.set_tags(family_id: family.id, job: "SyncJob")
      end
    end
  end

  def family_has_syncable_items?(family)
    family.plaid_items.any? ||
      family.simplefin_items.active.any? ||
      family.lunchflow_items.active.any?
  end
end
