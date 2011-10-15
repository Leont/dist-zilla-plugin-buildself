package Dist::Zilla::Plugin::BuildSelf;

use Moose;
with qw/Dist::Zilla::Role::BuildPL Dist::Zilla::Role::TextTemplate Dist::Zilla::Role::PrereqSource/;

use Dist::Zilla::File::InMemory;

has add_buildpl => (
	is => 'ro',
	isa => 'Bool',
	default => 1,
);

has template => (
	is  => 'ro',
	isa => 'Str',
	default => "use lib 'lib';\nuse {{ \$module }} {{ \$version }};\nBuild_PL(\@ARGV);\n",
);

has module => (
	is => 'ro',
	isa => 'Str',
	builder => '_module_builder',
	lazy => 1,
);

sub _module_builder {
	my $self = shift;
	(my $name = $self->zilla->name) =~ s/-/::/g;
	return $name;
}

has version => (
	is  => 'ro',
	isa => 'Str',
	default => '',
);

sub register_prereqs {
	my ($self) = @_;

	my $reqs = $self->zilla->prereqs->requirements_for('runtime', 'requires');
	$self->zilla->register_prereqs({ phase => 'configure' }, %{ $reqs->as_string_hash });

	return;
}

sub setup_installer {
	my ($self, $arg) = @_;

	if ($self->add_buildpl) {
		my $content = $self->fill_in_string($self->template, { module => $self->module, version => $self->version });
		my $file = Dist::Zilla::File::InMemory->new({ name => 'Build.PL', content => $content });
		$self->add_file($file);
	}

	return;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

# ABSTRACT: Build a Build.PL that uses the current module to build itself

=head1 DESCRIPTION

Unless you're writing a Build.PL compatible module builder, you should not be looking at this. The only purpose of this module is to bootstrap any such module on Dist::Zilla.

=attr module

The module used to build the current module. Defaults to the main module of the current distribution.

=attr version

The minimal version of the module, if any. Defaults to none.

=attr template

The template to use for the Build.PL script. This is a Text::Template string with two arguments as described above: C<$module> and C<$version>. Default is typical for the authors Build.PL ideas, YMMV.

=for Pod::Coverage
register_prereqs
setup_installer
=end
