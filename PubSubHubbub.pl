# PubSubHubbub for Movable Type
# Copyright: Six Apart, 2009-
# Author: Tatsuhiko Miyagawa
# License: Artistic and GPL v2

package MT::Plugin::PubSubHubbub;
use strict;
use base qw( MT::Plugin );

our $VERSION = "0.01";

use LWP::UserAgent;
use MT::Template;

my $plugin; $plugin = MT::Plugin::PubSubHubbub->new({
    name => 'PubSubHubbub',
    version => $VERSION,
    description => '<MT_TRANS phrase="Pings feed updates to PubSubHubbub hub(s).">',
    author_name => 'Tatsuhiko Miyagawa',
    author_link => 'http://bulknews.typepad.com/',
    blog_config_template => 'config.tmpl',
    settings    => MT::PluginSettings->new([
        [ 'hubs', { Default => '', Scope => 'blog' } ],
    ]),
    registry => {
        callbacks => {
            'cms_post_save.entry', sub { $plugin->send_ping(@_) },
        },
        tags => {
            function => {
                PubSubHubbubLinks => \&_hdlr_link_tags,
            },
        },
    },
});

MT->add_plugin($plugin);

sub send_ping {
    my($plugin, $cb, $app, $entry) = @_;

    my $blog = $entry->blog;

    my $ua = LWP::UserAgent->new(agent => join("/", $plugin->name, $plugin->version));
    my $tmpl = MT::Template->new_string(\'<$mt:Link template="feed_recent"$>');
    $tmpl->context->stash(blog => $blog);
    my $feed_url = $tmpl->build
        or die "Can't get feed URL: ", $tmpl->errstr;

    my @hubs = $plugin->get_config_value('hubs', "blog:" . $blog->id) =~ /(\S+)/g;
    for my $hub (@hubs) {
        my $res = $ua->post($hub, { "hub.mode" => "publish", "hub.url" => $feed_url });
        MT->log({ level => 'debug', message => "Pinged $hub: " . $res->status_line });
    }
}

sub _hdlr_link_tags {
    my($ctx, $args, $cond) = @_;
    my $blog = $ctx->stash('blog') or return '';

    my $tag = '';
    my @hubs = $plugin->get_config_value('hubs', "blog:" . $blog->id) =~ /(\S+)/g;
    for my $hub (@hubs) {
        $tag .= sprintf qq(<link rel="hub" href="%s" />\n), MT::Util::encode_xml($hub);
    }

    return $tag;
}

1;
