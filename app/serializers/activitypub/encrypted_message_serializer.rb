# frozen_string_literal: true

class ActivityPub::EncryptedMessageSerializer < ActivityPub::Serializer
  attributes :type, :origin, :target, :message_type,
             :cipher_text, :message_franking

  def type
    'EncryptedMessage'
  end

  def origin
    object.origin_device_id
  end

  def target
    object.target_device_id
  end

  def message_type
    object.type
  end

  def cipher_text
    object.body
  end
end
