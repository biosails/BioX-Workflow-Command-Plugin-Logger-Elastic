package BioX::Workflow::Command::stats::Plugin::Logger::Elastic;

use MooseX::App::Role;

use Data::Dumper;
use Number::Bytes::Human;
use File::Details;
use File::Basename;
use DateTime;

with 'HPC::Runner::Command::Plugin::Logger::Elastic';

our $human = Number::Bytes::Human->new(
    bs          => 1024,
    round_style => 'round',
    precision   => 2
);
our $dt = DateTime->now();

has 'submission_id' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $submission_id =
          $ENV{'HPCR_ES_SUBMISSION_ID'} || '';
        return $submission_id;
    },
);

has 'file_data' => (
    is      => 'rw',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub { [] },
);

around 'execute' => sub {
    my $orig = shift;
    my $self = shift;

    $self->$orig(@_);

    $self->search_elastic_file_index;
};

sub try_create_index {
    my $self = shift;

    try {
        $self->elasticsearch->indices->create( index => 'hpcrunner', );
    };

    ##Create initial document
}

around 'gen_row' => sub {
    my $orig = shift;
    my $self = shift;

    my $file         = shift;
    my $cond         = shift;
    my $sample       = shift;
    my $sample_files = shift;

    foreach my $file ( @{$sample_files} ) {

        my $file_href = {};
        $file_href->{sample}    = $sample;
        $file_href->{type}      = $cond;
        $file_href->{rule_name} = $self->rule_name;
        $file_href->{time_now}  = "$dt";

        #Stick this in here for compatibility with hpc-runner
        $file_href->{jobname} = $self->rule_name;

        my $rel = '';
        $rel = File::Spec->abs2rel($file);
        my $basename = basename($file);

        $file_href->{file_abs}      = $file;
        $file_href->{file_rel}      = $rel;
        $file_href->{file_base}     = $basename;
        $file_href->{submission_id} = $self->submission_id;

        #Does the file exist?
        if ( -e $file ) {
            $file_href->{exists} = 1;

            my $details = File::Details->new($file);
            my $hsize   = $human->format( $details->size );

            $file_href->{hsize} = $hsize;
        }
        else {
            $file_href->{exists} = 0;
        }
        push( @{ $self->file_data }, $file_href );
        $self->create_elastic_file_index($file_href);
    }

    $self->$orig( $file, $cond, $sample, $sample_files );
};

sub create_elastic_file_index {
    my $self      = shift;
    my $file_href = shift;

    my $doc = $self->elasticsearch->index(
        index => 'hpcrunner',
        type  => 'biox_stats',
        body  => $file_href,
    );
}

sub search_elastic_file_index {
    my $self = shift;

    my $doc = $self->elasticsearch->search(
        index => 'hpcrunner',
        type  => 'biox_stats',
        body  => {
            query => {
                bool => {
                    must => [
                        {
                            match => { sample => 'Sample_03' }
                        },
                        {
                            match => { type => 'INPUT' }
                        },
                    ],
                }
            }
        }
    );

}

1;
