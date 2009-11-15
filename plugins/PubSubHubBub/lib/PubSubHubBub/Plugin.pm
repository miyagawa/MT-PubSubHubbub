package PubSubHubBub::Plugin;

use strict;
use warnings;

sub send_ping {
    my($cb, $blog) = @_;
    my $plugin = MT->component('PubSubHubBub');

    my @hubs = $plugin->get_config_value('hubs', "blog:" . $blog->id) =~ /(\S+)/g;
    return unless @hubs;

    my $ua = MT->new_ua({ agent => join("/", $plugin->name, $plugin->version) });
    my $link = '<$mt:Link template="feed_recent"$>';
    my $tmpl = MT->model('template')->new_string(\$link);
    $tmpl->context->stash(blog => $blog);
    my $feed_url = $tmpl->build
        or die "Can't get feed URL: ", $tmpl->errstr;

    for my $hub (@hubs) {
        my $res = $ua->post($hub, { "hub.mode" => "publish", "hub.url" => $feed_url });
        MT->log("Pinged $hub: " . $res->status_line);
    }
}

sub _hdlr_link_tags {
    my($ctx, $args, $cond) = @_;

    my $plugin = MT->component('PubSubHubBub');
    my $blog = $ctx->stash('blog') or return '';

    my $tag = '';
    my @hubs = $plugin->get_config_value('hubs', "blog:" . $blog->id) =~ /(\S+)/g;
    for my $hub (@hubs) {
        $tag .= sprintf qq(<link rel="hub" href="%s" />\n), MT::Util::encode_xml($hub);
    }

    return $tag;
}

1;
