# $Id$

package EnsEMBL::Web::Component::LRG::Summary;

### NAME: EnsEMBL::Web::Component::LRG::Summary;
### Generates a context panel for an LRG page

### STATUS: Under development

### DESCRIPTION:
### Because the LRG page is a composite of different domain object views, 
### the contents of this component vary depending on the object generated
### by the factory

use strict;

use HTML::Entities qw(encode_entities);

use base qw(EnsEMBL::Web::Component::LRG);


sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(0);
}

sub content {
  my $self   = shift;
  my $object = $self->object;
  my $hub    = $self->hub;
  my $html   = '';

  ## Grab the description of the object

  if ($hub->action eq 'Genome' || !$object) {
    $html =
      'LRG (Locus Reference Genomic) sequences provide a stable genomic DNA framework ' .
      'for reporting mutations with a permanent ID and core content that never changes. ' . 
      'For more information, visit the <a href="http://www.lrg-sequence.org">LRG website</a>.';
  } else {
    my $lrg         = $object->Obj;
    my $param       = $hub->param('lrg');
		my $href        = $self->hub->species_defs->ENSEMBL_EXTERNAL_URLS->{'LRG'};
		   $href =~ s/###ID###/$param/;
    my $description = qq{LRG region <a rel="external" href="$href">$param</a>.};
    my @genes       = @{$lrg->get_all_Genes('LRG_import')||[]};
    my $db_entry    = $genes[0]->get_all_DBLinks('HGNC');
    my $slice       = $lrg->feature_Slice;
    my $gene_url    = $hub->url({
      type   => 'Gene',
      action => 'Summary',
      g      => $db_entry->[0]->display_id,
    });

    $description .= sprintf ' This LRG was created as a reference standard for the <a href="%s">%s</a> gene.', $gene_url, $db_entry->[0]->display_id;
    $description  =~ s/EC\s+([-*\d]+\.[-*\d]+\.[-*\d]+\.[-*\d]+)/$self->EC_URL($1)/e;
    
		my $source =  $genes[0]->source;
		my $source_url;
		$source = 'LRG' if ($source =~ /LRG/);
		$source_url = $self->hub->species_defs->ENSEMBL_EXTERNAL_URLS->{uc($source)};
		$source_url =~ s/###ID###//;
		
		if ($source_url) {
			$description .= qq{ Source: <a rel="external" href="$source_url">$source</a>.};
		}
		
    my $url = $hub->url({
      type   => 'Location',
      action => 'View',
      r      => $slice->seq_region_name . ':' . $slice->start . '-' . $slice->end
    });
    
    my $location_html = sprintf(
      '<a href="%s">%s: %s-%s</a> %s.',
      $url,
      $self->neat_sr_name($slice->coord_system->name, $slice->seq_region_name),
      $self->thousandify($slice->start),
      $self->thousandify($slice->end),
      $slice->strand < 0 ? ' reverse strand' : 'forward strand'
    );
    
    $html .= qq{
      <dl class="summary">
				<dt>Description</dt>
				<dd>$description</dd>
        <dt>Location</dt>
        <dd>$location_html</dd>
      </dl>
    };
    
    my $transcripts = $lrg->get_all_Transcripts(undef, 'LRG_import'); 

    my $count    = @$transcripts;
    my $plural_1 = 'are';
    my $plural_2 = 'transcripts';
    
    if ($count == 1) {
      $plural_1 = 'is'; 
      $plural_2 =~ s/s$//; 
    }
    
    my $hide = $self->hub->get_cookies('ENSEMBL_transcripts') eq 'close';
    
		my $action = $hub->action;
		
		my %url_params = (
      type   => 'LRG',
      #action => $action eq 'Summary' ? 'Summary' : $action
			lrg => $param
    );
		
    $html .= sprintf(qq{
      <dl class="summary">
        <dt id="transcripts" class="toggle_button" title="Click to toggle the transcript table"><span>Transcripts</span><em class="%s"></em></dt>
        <dd>There $plural_1 $count $plural_2 in this region:</dd>
        <dd class="toggle_info"%s>Click the plus to show the transcript table</dd>
      </dl>
      <div class="toggleTable_wrapper">
        <table class="toggle_table" id="transcripts_table" summary="List of transcripts for this region - along with translation information and type"%s>
          <thead>
            <tr>
              <th>Name</th>
              <th>Transcript ID</th>
              <th>Description</th> 
            </tr>
          </thead>
          <tbody>
      },
      $hide ? 'closed' : 'open',
      $hide ? '' : ' style="display:none"',
      $hide ? ' style="display:none"' : ''
    );
 
    foreach (map $_->[2], sort { $a->[0] cmp $b->[0] || $a->[1] cmp $b->[1] } map [$_->external_name, $_->stable_id, $_], @$transcripts) {
      my $transcript = encode_entities($_->stable_id);
      #my $protein    = $_->translation ? 'LRG Protein' : 'No protein product';
			
			my $url = $hub->url({ %url_params, lrgt => $_->stable_id });
			
			my $tr_id = qq{<a href="$url">$transcript</a>};
			
      $html .= sprintf('
        <tr%s>      
          <th>%s</th>
          <td>%s</td>
          <td>Fixed transcript for reporting purposes</td>
        </tr>',
        $_->stable_id eq $transcript ? ' class="active"' : '',
        encode_entities($_->display_xref ? $_->display_xref->display_id : '-'),
        $tr_id, #$transcript,
      );
    }
    
    $html .= '
          </tbody>
        </table>
      </div>
    ';
  }
  
  return qq{<div class="summary_panel">$html</div>};
}

1;
