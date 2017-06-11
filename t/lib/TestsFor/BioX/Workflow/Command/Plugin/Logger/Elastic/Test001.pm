package TestsFor::BioX::Workflow::Command::Plugin::Logger::Elastic::Test001;

use Test::Class::Moose;
use Cwd;
use FindBin qw($Bin);
use File::Path qw(make_path remove_tree);
use Capture::Tiny ':all';

extends 'TestMethods::Base';

sub test_001 {
  require_ok('BioX::Workflow::Command::Plugin::Logger::Elastic');
  require_ok('BioX::Workflow::Command::stats::Plugin::Logger::Elastic');
}


1;
