Rails.application.config.middleware.use OmniAuth::Builder do
  provider :slack, '2694002599255.2695608634823', '918c05c555302903afe2d08c0a2d4a20', scope: 'identity.basic'
end
