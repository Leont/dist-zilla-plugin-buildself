package Dist::Zilla::Plugin::BuildSelf;

use Moose;
with qw/Dist::Zilla::Role::BuildPL Dist::Zilla::Role::TextTemplate Dist::Zilla::Role::PrereqSource/;

use Dist::Zilla::File::InMemory;

has template => (
	is  => 'ro',
	isa => 'Str',
	default => "use lib 'lib';\nuse {{ \$module }} {{ \$version }};\nBuild_PL(\@ARGV);\n",
);

has version => (
	is  => 'ro',
	isa => 'Str',
	default => '0.001',
);

sub register_prereqs {
	my ($self) = @_;

	my $reqs = $self->zilla->prereqs->requirements_for('runtime', 'requires');
	$self->zilla->register_prereqs({ phase => 'configure' }, %{ $reqs->as_string_hash });

	return;
}

sub setup_installer {
	my ($self, $arg) = @_;

	(my $name = $self->zilla->name) =~ s/-/::/g;
	my $content = $self->fill_in_string($self->template, { version => $self->version, module => $name});
	my $file = Dist::Zilla::File::InMemory->new({ name => 'Build.PL', content => $content });
	$self->add_file($file);

	return;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

# ABSTRACT: Build a Build.PL that uses the current module to build itself
