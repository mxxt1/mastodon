# frozen_string_literal: true

class ActivityPub::MessageFrankingSerializer < ActivityPub::Serializer
  context :security

  context_extensions :message_franking

  class DigestSerializer < ActivityPub::Serializer
    attributes :type, :digest_algorithm, :digest_value

    def type
      'Digest'
    end

    def digest_algorithm
      'http://www.w3.org/2000/09/xmldsig#hmac-sha256'
    end

    def digest_value
      object.hmac
    end
  end

  attributes :type, :published, :actor, :target

  has_one :digest, serializer: DigestSerializer

  def type
    'MessageFranking'
  end

  def published
    Time.now.utc.iso8601
  end

  def digest
    object
  end

  def actor
    ActivityPub::TagManager.instance.uri_for(object.source_account)
  end

  def target
    ActivityPub::TagManager.instance.uri_for(object.target_account)
  end
end
