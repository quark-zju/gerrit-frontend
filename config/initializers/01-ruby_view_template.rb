# by Ryan Bates (@rbates)
# https://twitter.com/rbates/status/243204610565746689
ActionView::Template.register_template_handler(:rb, :source.to_proc)
