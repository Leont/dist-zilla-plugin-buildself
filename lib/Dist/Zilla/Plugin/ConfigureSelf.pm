package Dist::Zilla::Plugin::ConfigureSelf;

use Moose;

with qw/Dist::Zilla::Role::ConfigureSelf/;

1;


# ABSTRACT: Build a Build.PL that uses the current module to build itself

=head1 DESCRIPTION

This plugin copies any runtime requirements to configure requirements. This can be useful for bootstrapping install tools, it should not be necessary for almost anything else.

It takes a single option, C<sanatize_for>, that takes a perl version. If set any prerequisites provided by that version of perl will be filtered out of the configure requirements.
