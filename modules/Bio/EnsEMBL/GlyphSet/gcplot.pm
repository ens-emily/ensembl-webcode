package Bio::EnsEMBL::GlyphSet::gcplot;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet;
@ISA = qw(Bio::EnsEMBL::GlyphSet);
use Bio::EnsEMBL::Glyph::Rect;
use Bio::EnsEMBL::Glyph::Intron;
use Bio::EnsEMBL::Glyph::Text;
use Bio::EnsEMBL::Glyph::Composite;
use Bio::EnsEMBL::Glyph::Line;
use Bump;

sub init_label {
    my ($self) = @_;
    return if( defined $self->{'config'}->{'_no_label'} );
    my $label = new Bio::EnsEMBL::Glyph::Text({
        'text'      => '%GC',
        'font'      => 'Small',
        'absolutey' => 1,
    });
    $self->label($label);
}

sub _init {
    my ($self) = @_;

    return unless ($self->strand() == -1);

    # check we are not in a big gap!
    my @map_contigs = $self->{'container'}->_vmap->each_MapContig();
    return unless (@map_contigs);

    my $VirtualContig   = $self->{'container'};
    my $Config          = $self->{'config'};
    my $vclen           = $VirtualContig->length();
    return if ($vclen < 10000);    # don't want a GC plot for very short sequences

    my $h               = 0;
    my $highlights      = $self->highlights();
    my $feature_colour  = $Config->get('gcplot','hi');
    my $alt_colour      = $Config->get('gcplot','low');
    my $cmap            = $Config->colourmap();
    my $black           = $cmap->id_by_name('black');
    my $red             = $cmap->id_by_name('red');
    my $rust            = $cmap->id_by_name('rust');
    my $colour          = $Config->get('gcplot','col');
    my $line_colour     = $Config->get('gcplot','line');
    
    my $im_width        = $Config->image_width();
    my $divs            = int($im_width/2);
    my $divlen          = $vclen/$divs;
    
    #print STDERR "Divs = $divs\n";
    my $seq = $VirtualContig->seq();
    my @gc  = ();
    my $min = 100;
    my $max = 0;
    
    $self->push($line);
    for (my $i=0; $i<$divs; $i++){
        my $subseq = substr($seq, int($i*$divlen), int($divlen));
#       my $G = $subseq =~ tr/G/G/; my $C = $subseq =~ tr/C/C/;
        my $GC = $subseq =~ tr/GC//;
        my $percent = 99;
        if ( length($subseq)>0 ) { # catch divide by zero....
            $percent = $GC / length($subseq);
            $percent = $percent < .25 ? 0 : ($percent >.75 ? .5 : $percent -.25);
            $percent *= 40;
        }
        push (@gc, $percent);
    }
        
    my $range = $max - $min;
    my $percent = shift @gc;
    my $count = 0;
    while(@gc) {
        my $new = shift @gc;   
        unless($percent==99 || $new==99) {
            $self->push(
                new Bio::EnsEMBL::Glyph::Line({
                    'x'            => $count * $divlen,
                    'y'            => 20 - $percent,
                    'width'        => $divlen,
                    'height'       => $percent - $new,
                    'colour'       => $colour,
                    'absolutey'    => 1,
                })
            ); 
        }
        $percent = $new;
        $count++;
    }
    my $line = new Bio::EnsEMBL::Glyph::Line({
        'x'         => 0,
        'y'         => 10, # 50% point for line
        'width'     => $vclen,
        'height'    => 0,
        'colour'    => $line_colour,
        'absolutey' => 1,
    });
    
}            
#    my $fontname = "Tiny";
#    #my $text = "% GC by $divlen bp window [dotted line shows 50%] Max = $max %, Min = $min %";
#    my $text =  "% GC by $divlen bp window. [Max = $max%, Min = $min%]";
#
#    my ($tw,$th)     = $Config->texthelper->px2bp($fontname);
#    my $bp_textwidth = $tw * length($text) * 1.1; # add 10% for scaling text
#
#    my $tglyph = new Bio::EnsEMBL::Glyph::Text({
#        'x'         => $vclen/2 - $bp_textwidth/2,
#        'y'         => 22,
#        'height'    => $Config->texthelper->height($fontname),
#        'font'      => $fontname,
#        'colour'    => $black,
#        'text'      => $text,
#        'absolutey' => 1,
#    });
#    #$self->push($tglyph);

1;

