require "test_helper"

class SyncJobTest < ActiveJob::TestCase
  test "sync is performed when sync is provided" do
    syncable = accounts(:depository)

    sync = syncable.syncs.create!(window_start_date: 2.days.ago.to_date)

    sync.expects(:perform).once

    SyncJob.perform_now(sync)
  end

  test "all families with provider items are synced when no sync is provided" do
    # This test verifies the cron job behavior
    family = families(:dylan_family)

    # Mock the family to have a provider item
    SimplefinItem.any_instance.stubs(:active).returns(SimplefinItem.where(family: family))
    family.expects(:sync_later).once

    SyncJob.perform_now
  end
end
