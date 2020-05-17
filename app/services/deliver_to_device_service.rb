# frozen_string_literal: true

class DeliverToDeviceService < BaseService
  include Payloadable

  class EncryptedMessage < ActiveModelSerializers::Model
    attributes :origin_device_id, :target_device_id,
               :type, :body, :message_franking
  end

  class MessageFranking < ActiveModelSerializers::Model
    attributes :hmac, :source_account, :target_account
  end

  def call(source_account, source_device, options = {})
    @source_account   = source_account
    @source_device    = source_device
    @target_account   = Account.find(options[:account_id])
    @target_device_id = options[:device_id]
    @body             = options[:body]
    @type             = options[:type]
    @hmac             = options[:hmac]

    sign_message_franking!

    if @target_account.local?
      deliver_to_local!
    else
      deliver_to_remote!
    end
  end

  private

  def sign_message_franking!
    @message_franking = ActivityPub::LinkedDataSignature.new(message_franking).sign!(Account.representative)
  end

  def deliver_to_local!
    target_device = @target_account.devices.find_by!(device_id: @target_device_id)
    target_device.encrypted_messages.create!(from_account: @source_account, from_device_id: @source_device.device_id, type: @type, body: @body, message_franking: Oj.dump(@message_franking))
  end

  def deliver_to_remote!
    ActivityPub::DeliveryWorker.perform_async(encrypted_message_json, @source_account.id, @target_account.inbox_url)
  end

  def encrypted_message_json
    Oj.dump(serialize_payload(EncryptedMessage.new(origin_device_id: @source_device.device_id, target_device_id: @target_device_id, type: @type, body: @body, message_franking: @message_franking), ActivityPub::EncryptedMessageSerializer))
  end

  def message_franking
    serialize_payload(MessageFranking.new(source_account: @source_account, target_account: @target_account, hmac: @hmac), ActivityPub::MessageFrankingSerializer)
  end
end
