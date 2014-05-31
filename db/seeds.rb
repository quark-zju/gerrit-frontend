[
  {
    base_url: 'https://review.openstack.org',
    allow_anonymous: true,
    is_local_net: false,
  },
  {
    base_url: 'https://scm.service.163.org',
    allow_anonymous: false,
    is_local_net: true,
  }
].each do |data|
  Host.where(base_url: data[:base_url]).first_or_create! data
end
