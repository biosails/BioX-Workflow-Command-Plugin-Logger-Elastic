use File::Spec::Functions qw( catdir  );
use FindBin qw( $Bin  );
use Test::Class::Moose::Load catdir( $Bin, 'lib' );
use Test::Class::Moose::Runner;

##Run the main applications tests

Test::Class::Moose::Runner->new( test_classes =>
      [ 'TestsFor::BioX::Workflow::Command::Plugin::Logger::Elastic::Test001', ], )
  ->runtests;
