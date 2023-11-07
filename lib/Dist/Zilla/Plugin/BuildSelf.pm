package Dist::Zilla::Plugin::BuildSelf;

use Moose;
with qw/Dist::Zilla::Role::BuildPL Dist::Zilla::Role::TextTemplate Dist::Zilla::Role::PrereqSource/;

use experimental 'signatures', 'postderef';

use Dist::Zilla::File::InMemory;

has add_buildpl => (
	is => 'ro',
	isa => 'Bool',
	default => sub($self) {
		return not grep { $_->name eq 'Build.PL' } $self->zilla->files->@*;
	},
);

has template => (
	is  => 'ro',
	isa => 'Str',
	default => "use {{ \$minimum_perl }};\nuse lib 'lib';\nuse {{ \$module }};\nBuild_PL(\\\@ARGV, \\\%ENV);\n",
);

has module => (
	is => 'ro',
	isa => 'Str',
	builder => '_module_builder',
	lazy => 1,
);

has auto_configure_requires => (
	is => 'ro',
	isa => 'Bool',
	default => 1,
);

has minimum_perl => (
	is      => 'ro',
	isa     => 'Str',
	lazy    => 1,
	default => sub($self) {
		return $self->zilla->prereqs->requirements_for('runtime', 'requires')->requirements_for_module('perl') || '5.006'
	},
);

has sanatize_for => (
	is => 'ro',
	isa => 'Str',
	default => 0,
);

sub _module_builder($self) {
	return $self->zilla->name =~ s/-/::/gr;
}

sub register_prereqs($self) {
	if ($self->auto_configure_requires) {
		my $prereqs = $self->zilla->prereqs;
		if (my $for = $self->sanatize_for) {
			require CPAN::Meta::Prereqs::Filter;
			$prereqs = CPAN::Meta::Prereqs::Filter::filter_prereqs($prereqs, omit_core => $for);
		}
		my $reqs = $prereqs->requirements_for('runtime', 'requires');
		$self->zilla->register_prereqs({ phase => 'configure' }, $reqs->as_string_hash->%*);
	}
}

sub setup_installer($self) {
	if ($self->add_buildpl) {
		my $content = $self->fill_in_string($self->template, { module => $self->module, minimum_perl => $self->minimum_perl });
		my $file = Dist::Zilla::File::InMemory->new({ name => 'Build.PL', content => $content });
		$self->add_file($file);
	}
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

# ABSTRACT: Build a Build.PL that uses the current module to build itself

=head1 DESCRIPTION

Unless you're writing a Build.PL compatible module builder, you should not be looking at this. The only purpose of this module is to bootstrap any such module on Dist::Zilla.

=attr add_buildpl

If enabled it will generate a F<Build.PL> file for you. Defaults to true if no Build.PL file is given.

=attr auto_configure_requires

If enabled it will automatically add the runtime requirements of the dist to the configure requirements.

=attr sanatize_for

If non-zero it will filter modules provided by the given perl version from the configure dependencies.

=attr module

The module used to build the current module. Defaults to the main module of the current distribution.

=attr minimum_perl

The minimal version of perl needed to run this Build.PL. It defaults to the current runtime requirements' value for C<perl>, or C<5.006> otherwise.

=attr template

The template to use for the Build.PL script. This is a Text::Template string with the arguments as described above: C<$module> and C<$minimum_perl>. Default is typical for the author's Build.PL ideas, YMMV.
