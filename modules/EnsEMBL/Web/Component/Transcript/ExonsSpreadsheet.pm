package EnsEMBL::Web::Component::Transcript::ExonsSpreadsheet;

use strict;

use EnsEMBL::Web::Document::SpreadSheet;

use base qw(EnsEMBL::Web::Component::Transcript EnsEMBL::Web::Component::TextSequence);

sub _init {
  my $self = shift;
  $self->cacheable(1);
  $self->ajaxable(1);
}

sub content {
  my $self         = shift;
  my $object       = $self->object; 
  my $only_exon    = $object->param('oexon') eq 'yes'; # display only exons
  my $entry_exon   = $object->param('exon');
  my $transcript   = $object->Obj;
  my @exons        = @{$transcript->get_all_Exons};
  my $strand       = $exons[0]->strand;
  my $chr_name     = $exons[0]->slice->seq_region_name;
  my $i            = 0;
  my @data;
  
  my $config = {
    display_width   => $object->param('seq_cols') || 60,
    sscon           => $object->param('sscon')    || 25,   # no of bp to show either side of a splice site
    flanking        => $object->param('flanking') || 50,   # no of bp up/down stream of transcript
    full_seq        => $object->param('fullseq') eq 'yes', # flag to display full sequence (introns and exons)
    variation       => $object->param('variation'),
    coding_start    => $transcript->coding_region_start,
    coding_end      => $transcript->coding_region_end,
    strand          => $strand,
    maintain_colour => 1
  };
  
  $config->{'variation'} = 'off' unless $object->species_defs->databases->{'DATABASE_VARIATION'};
  
  foreach my $exon (@exons) {
    my $next_exon  = $exons[++$i];
    my $exon_id    = $exon->stable_id;
    my $exon_start = $exon->start;
    my $exon_end   = $exon->end;
    
    $exon_id = "<strong>$exon_id</strong>" if $entry_exon && $entry_exon eq $exon_id;
    
    $config->{'html_template'} = '<pre class="exons_exon">%s</pre>';
    
    my $sequence = $self->get_exon_sequence_data($config, $exon);
    
    push @data, {
      Number     => $i,
      exint      => sprintf('<a href="%s">%s</a>', $object->_url({ type => 'Location', action => 'View', r => "$chr_name:" . ($exon_start - 50) . '-' . ($exon_end + 50) }), $exon_id),
      Start      => $self->thousandify($exon_start),
      End        => $self->thousandify($exon_end),
      StartPhase => $exon->phase     >= 0 ? $exon->phase     : '-',
      EndPhase   => $exon->end_phase >= 0 ? $exon->end_phase : '-',
      Length     => $self->thousandify(scalar @$sequence),
      Sequence   => $self->build_sequence([ $sequence ], $config)
    };
    
    # Add intronic sequence
    if ($next_exon && !$only_exon) {
      my ($intron_start, $intron_end) = $strand == 1 ? ($exon_end + 1, $next_exon->start - 1) : ($next_exon->end + 1, $exon_start - 1);
      my $intron_length = $intron_end - $intron_start + 1;
      my $intron_id     = "Intron $i-" . ($i+1);
      my $sequence      = $self->get_intron_sequence_data($config, $exon, $next_exon, $intron_start, $intron_end, $intron_length);
      
      $config->{'html_template'} = '<pre class="exons_intron">%s</pre>';
      
      push @data, {
        Number   => '&nbsp;',
        exint    => sprintf('<a href="%s">%s</a>', $object->_url({ type => 'Location', action => 'View', r => "$chr_name:" . ($intron_start - 50) . '-' . ($intron_end + 50) }), $intron_id),
        Start    => $self->thousandify($intron_start),
        End      => $self->thousandify($intron_end),
        Length   => $self->thousandify($intron_length),
        Sequence => $self->build_sequence([ $sequence ], $config)
      };
    }
  }
  
  # Add flanking sequence
  if ($config->{'flanking'} && !$only_exon) {
    my ($upstream, $downstream) = $self->get_flanking_sequence_data($config, $exons[0], $exons[-1]);
    
    $config->{'html_template'} = '<pre class="exons_flank">%s</pre>';
    
    unshift @data, {
      exint    => "5' upstream sequence", 
      Sequence => $self->build_sequence([ $upstream ], $config)
    };
    
    $config->{'html_template'} = '<pre class="exons_flank">%s</pre>';
    
    push @data, { 
      exint    => "3' downstream sequence", 
      Sequence => $self->build_sequence([ $downstream ], $config)
    };
  }
  
  my $table = new EnsEMBL::Web::Document::SpreadSheet([
      { key => 'Number',     title => 'No.',           width => '6%',  align => 'center' },
      { key => 'exint',      title => 'Exon / Intron', width => '15%', align => 'center' },
      { key => 'Start',      title => 'Start',         width => '10%', align => 'right'  },
      { key => 'End',        title => 'End',           width => '10%', align => 'right'  },
      { key => 'StartPhase', title => 'Start Phase',   width => '7%',  align => 'center' },
      { key => 'EndPhase',   title => 'End Phase',     width => '7%',  align => 'center' },
      { key => 'Length',     title => 'Length',        width => '10%', align => 'right'  },
      { key => 'Sequence',   title => 'Sequence',      width => '15%', align => 'left'   }
    ], 
    \@data, 
    { margin => '1em 0px' }
  );
  
  return $table->render;
}

sub get_exon_sequence_data {
  my $self = shift;
  my ($config, $exon) = @_;
  
  my $coding_start = $config->{'coding_start'};
  my $coding_end   = $config->{'coding_end'};
  my $strand       = $config->{'strand'};
  my $seq          = uc $exon->seq->seq;
  my $seq_length   = length $seq;
  my $exon_start   = $exon->start;
  my $exon_end     = $exon->end;
  my $utr_start    = $coding_start > $exon_start; # exon starts with UTR
  my $utr_end      = $coding_end   < $exon_end;   # exon ends with UTR
  
  my @sequence = map {{ letter => $_ }} split //, $seq;
  
  if ($utr_start || $utr_end) {
    my ($coding_length, $utr_length) = $strand == 1 ? ($seq_length - ($exon_end - $coding_end), $coding_start - $exon_start) : ($exon_end - $coding_start + 1, $exon_end - $coding_end);
    
    $sequence[0]->{'class'} = 'eu' if ($strand == 1 && $utr_start) || ($strand == -1 && $utr_end);
    
    my ($open_span, $close_span) = $strand == 1 ? ($utr_end, $utr_start) : ($utr_start, $utr_end);
    
    for (my $j = 0; $j < scalar @sequence; $j++) {
      if ($open_span && $j == $coding_length) {
        $sequence[$j]->{'class'} = 'eu';
      } elsif ($close_span && $j == $utr_length) {
        $sequence[$j]->{'class'} = 'exon0';
      }
    }
  } elsif ($coding_end < $exon_start || $coding_start > $exon_end) {
    $sequence[0]->{'class'} = 'eu';
  }
  
  if ($config->{'variation'} ne 'off') {
    foreach my $vf (@{$exon->feature_Slice->get_all_VariationFeatures}) {
      for ($vf->start-1..$vf->end-1) {
        $sequence[$_]->{'class'} .= ' sn';
        $sequence[$_]->{'title'} .= ($sequence[$_]->{'title'} ? ', ' : '') . $vf->variation_name;
      }
    }
  }
  
  return \@sequence;
}

sub get_intron_sequence_data {
  my $self = shift;
  my ($config, $exon, $next_exon, $intron_start, $intron_end, $intron_length) = @_;
  
  my $display_width = $config->{'display_width'};
  my $strand        = $config->{'strand'};
  my $sscon         = $config->{'sscon'};
  my @dots          = map {{ letter => $_ }} split //, '.' x ($display_width - 2*($sscon % ($display_width/2)));
  my @sequence;
  
  eval {
    if (!$config->{'full_seq'} && $intron_length > ($sscon * 2)) {
      my $start = { slice => $exon->slice->sub_Slice($intron_start, $intron_start + $sscon - 1, $strand) };
      my $end   = { slice => $next_exon->slice->sub_Slice($intron_end - ($sscon - 1), $intron_end, $strand) };
      
      $start->{'sequence'} = [ map {{ letter => $_ }} split //, lc $start->{'slice'}->seq ];
      $end->{'sequence'}   = [ map {{ letter => $_ }} split //, lc $end->{'slice'}->seq   ];
      
      if ($config->{'variation'} eq 'on') {
        foreach my $i ($start, $end) {
          foreach my $vf (@{$i->{'slice'}->get_all_VariationFeatures}) {
            for ($vf->start-1..$vf->end-1) {
              $i->{'sequence'}->[$_]->{'class'} .= ' sn';
              $i->{'sequence'}->[$_]->{'title'} .= ($i->{'sequence'}->[$_]->{'title'} ? ', ' : '') . $vf->variation_name;
            }
          }
        }
      }
      
      @sequence = $strand == 1 ? (@{$start->{'sequence'}}, @dots, @{$end->{'sequence'}}) : (@{$end->{'sequence'}}, @dots, @{$start->{'sequence'}});
    } else {
      my $slice = $exon->slice->sub_Slice($intron_start, $intron_end, $strand);
      
      @sequence = map {{ letter => $_ }} split //, lc $slice->seq;
      
      if ($config->{'variation'} eq 'on') {
        foreach my $vf (@{$slice->get_all_VariationFeatures}) {
          for ($vf->start-1..$vf->end-1) {
            $sequence[$_]->{'class'} .= ' sn';
            $sequence[$_]->{'title'} .= ($sequence[$_]->{'title'} ? ', ' : '') . $vf->variation_name;
          }
        }
      }
    }
  };
  
  return \@sequence;
}

sub get_flanking_sequence_data {
  my $self = shift;
  my ($config, $first_exon, $last_exon) = @_;
  
  my $display_width = $config->{'display_width'};
  my $strand        = $config->{'strand'};
  my $flanking      = $config->{'flanking'};
  my @dots          = map {{ letter => $_ }} split //, '.' x ($display_width - ($flanking % $display_width));
  my ($upstream, $downstream);
  
  if ($strand == 1) {
    $upstream   = { slice => $first_exon->slice->sub_Slice($first_exon->start - $flanking, $first_exon->start - 1, $strand) };
    $downstream = { slice => $last_exon->slice->sub_Slice($last_exon->end + 1, $last_exon->end + $flanking, $strand)        };
  } else {
    $upstream   = { slice => $first_exon->slice->sub_Slice($first_exon->end + 1, $first_exon->end + $flanking, $strand)  };
    $downstream = { slice => $last_exon->slice->sub_Slice($last_exon->start - $flanking, $last_exon->start - 1, $strand) };
  }
  
  $upstream->{'sequence'}   = [ map {{ letter => $_ }} split //, lc $upstream->{'slice'}->seq   ];
  $downstream->{'sequence'} = [ map {{ letter => $_ }} split //, lc $downstream->{'slice'}->seq ];
  
  if ($config->{'variation'} eq 'on') {
    foreach my $f ($upstream, $downstream) {
      foreach my $vf (@{$f->{'slice'}->get_all_VariationFeatures}) {
        for ($vf->start-1..$vf->end-1) {
          $f->{'sequence'}->[$_]->{'class'} .= ' sn';
          $f->{'sequence'}->[$_]->{'title'} .= ($f->{'sequence'}->[$_]->{'title'} ? ', ' : '') . $vf->variation_name;
        }
      }
    }
  }
  
  my @upstream_sequence   = (@dots, @{$upstream->{'sequence'}});
  my @downstream_sequence = (@{$downstream->{'sequence'}}, @dots);
  
  return (\@upstream_sequence, \@downstream_sequence);
}

1;
