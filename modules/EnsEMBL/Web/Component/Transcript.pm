package EnsEMBL::Web::Component::Transcript;

use EnsEMBL::Web::Component;
use EnsEMBL::Web::Form;

use base qw(EnsEMBL::Web::Component);

use Data::Dumper;
use strict;
use warnings;
use EnsEMBL::Web::Form;
use CGI qw(escapeHTML);

no warnings "uninitialized";

## No sub stable_id   <- uses Gene's stable_id
## No sub name        <- uses Gene's name
## No sub description <- uses Gene's description
## No sub location    <- uses Gene's location call

sub non_coding_error {
  my $self = shift;
  return $self->_error( 'No protein product', '<p>This transcript does not have a protein product</p>' );
}
sub Summary {
  my( $panel, $object ) =@_;
  my $ob = $object->Obj;

  my $location_html = sprintf( '<a href="/%s/Location/View?r=%s:%s-%s">%s: %s-%s</a> %s',
    $object->species,
    $object->seq_region_name,
    $object->seq_region_start,
    $object->seq_region_end,
    $object->neat_sr_name( $object->seq_region_type, $object->seq_region_name ),
    $object->thousandify( $object->seq_region_start ),
    $object->thousandify( $object->seq_region_end ),
    $object->seq_region_strand < 0 ? ' reverse strand' : 'forward strand'
  );

  my $description = escapeHTML( $object->trans_description() );
  if( $description ) {
    $description =~ s/EC\s+([-*\d]+\.[-*\d]+\.[-*\d]+\.[-*\d]+)/EC_URL($object,$1)/e;
    $description =~ s/\[\w+:([\w\/]+)\;\w+:(\w+)\]//g;
    my($edb, $acc) = ($1, $2);
    $description .= qq( <span class="small">@{[ $object->get_ExtURL_link("Source: $edb $acc",$edb, $acc) ]}</span>) if $acc;
  }

  $panel->add_description( $description );
  $panel->add_row( 'Location', $location_html );
#  if( $ob->can('analysis') ) {
#    my $desc = $ob->analysis->description;
#    $panel->add_row( 'Method',   escapeHTML( $desc ) ) if $desc;
#  }
  my $gene = $object->core_objects->gene;
  my $transcripts = $gene->get_all_Transcripts;
  my $count = @$transcripts;
  if( $count > 1 ) {
    my $html = '
        <table id="transcripts" style="display:none">';
    foreach( sort { $a->stable_id cmp $b->stable_id } @$transcripts ) {
      my $url = $object->_url({
        'type'   => 'Transcript',
  'action' => $object->action,
        't'      => $_->stable_id
      });
      $html .= sprintf( '
          <tr%s>
      <th>%s</th>
      <td><a href="%s">%s</a></td>
    </tr>',
  $_->stable_id eq $object->stable_id ? ' class="active"' : '',
        $_->display_xref ? $_->display_xref->display_id : 'Novel',
        $url,
        $_->stable_id
      );

    }
    $html .= '
        </table>';
    $panel->add_row( 'Gene', sprintf(q(<div id="transcripts_text">Is a product of gene %s - There are %d transcripts in this gene:</div> %s), $gene->stable_id, $count, $html ));
  } else {
    $panel->add_row( 'Gene', sprintf(q(<div style="float:left">Is the product of gene %s.</div>), $gene->stable_id ));

  }
#  $panel->add_row( 'Location', 'location' );
}

sub tn_external {
  my( $panel, $object ) = @_;
  my $DO = $object->Obj;
  my $data_type;
  my $URL_KEY;
  my $type      = $DO->analysis->logic_name;
  if( $type eq 'GID' ) {
    $data_type = 'GeneID';
    $URL_KEY   = 'TETRAODON_ABINITIO';
  } elsif( $type eq 'GSC' ) {
    $data_type = 'Genscan';
    $URL_KEY   = 'TETRAODON_ABINITIO';
  } else {
    $data_type = 'Genewise';
    $URL_KEY   = 'TETRAODON_GENEWISE';
  }
  $panel->add_row( 'External links',
    qq(<p><strong>$data_type:</strong> @{[$object->get_ExtURL_link( $DO->stable_id, $URL_KEY, $DO->stable_id )]}</p>)
  );
  return 1;
}
sub information {
  my( $panel, $object ) = @_;
  my $label = "Transcript information";
  my $exons     = @{ $object->Obj->get_all_Exons }; 
  my $basepairs = $object->thousandify( $object->Obj->seq->length );
  my $residues  = $object->Obj->translation ? $object->thousandify( $object->Obj->translation->length ): 0;
   
  my $HTML = "<p><strong>Exons:</strong> $exons <strong>Transcript length:</strong> $basepairs bps";
     $HTML .= " <strong>Translation length:</strong> $residues residues" if $residues;
     $HTML .="</p>\n";
  if( $object->gene ) {
     my $gene_id   = $object->gene->stable_id;
     $HTML .= qq(<p>This transcript is a product of gene: <a href="/@{[$object->species]}/geneview?gene=$gene_id;db=@{[$object->get_db]}">$gene_id</a></p>\n);
  }
  $panel->add_row( $label, $HTML );
  return 1;
}

sub additional_info {
  my( $panel, $object ) = @_;
  my $label = "Transcript information";
  my $exons     = @{ $object->Obj->get_all_Exons };
  my $basepairs = $object->thousandify( $object->Obj->seq->length );
  my $residues  = $object->Obj->translation ? $object->thousandify( $object->Obj->translation->length ): 0;
  my $gene_id   = $object->gene->stable_id;

  my $HTML = "<p><strong>Exons:</strong> $exons <strong>Transcript length:</strong> $basepairs bps";
     $HTML .= " <strong>Protein length:</strong> $residues residues" if $residues;
     $HTML .="</p>\n";
  my $species = $object->species();
  my $query_string = "transcript=@{[$object->stable_id]};db=@{[$object->get_db]}";
     $HTML .=qq(<p>[<a href="/$species/transview?$query_string">Further Transcript info</a>] [<a href="/$species/exonview?$query_string">Exon information</a>]);
  if( $residues ) {
     $HTML .=qq( [<a href="/$species/protview?$query_string">Protein information</a>]);
  }
     $HTML .=qq(</p>);
  $panel->add_row( $label, $HTML );
  return 1;
}


sub gkb {
  my( $panel, $transcript ) = @_;
  my $label = 'Genome KnowledgeBase';
  unless ($transcript->__data->{'links'}){
    my @similarity_links = @{$transcript->get_similarity_hash($transcript->Obj)};
    return unless (@similarity_links);
    _sort_similarity_links($transcript, @similarity_links);
  }
  return unless $transcript->__data->{'links'}{'gkb'};
  my $GKB_hash = $transcript->__data->{'links'}{'gkb'};

  my $html =  qq( <strong>The following identifiers have been mapped to this entry via Genome KnowledgeBase:</strong><br />);

  my $urls = $transcript->ExtURL;
  $html .= qq(<table cellpadding="4">);
  foreach my $db (sort keys %{$GKB_hash}){
    $html .= qq(<tr><th>$db</th><td><table>);
    foreach my $GKB (@{$GKB_hash->{$db}}){
      my $primary_id = $GKB->primary_id;
      my ($t, $display_id) = split ':', $primary_id ;
      my $description = $GKB->description;
      $html .= '<tr><td>'.$transcript->get_ExtURL_link( $display_id, 'GKB', $primary_id) .'</td>
        <td>'.$description.'</td>
      </tr>';
    }
    $html .= qq(</table></td></tr>)
  }
  $html .= qq(</table>);
  $panel->add_row( $label, $html );
}

sub alternative_transcripts {
  my( $panel, $transcript ) = @_;
  _matches( $panel, $transcript, 'alternative_transcripts', 'Alternative transcripts', 'ALT_TRANS' );
}

sub oligo_arrays {
  my( $panel, $transcript ) = @_;
  _matches( $panel, $transcript, 'oligo_arrays', 'Oligo Matches', 'ARRAY' );
}

sub literature {
  my( $panel, $transcript ) = @_;
  _matches( $panel, $transcript, 'literature', 'References', 'LIT' );
}

sub similarity_matches {
  my( $panel, $transcript ) = @_;
  _matches( $panel, $transcript, 'similarity_matches', 'Similarity Matches', 'PRIMARY_DB_SYNONYM', 'MISC' );
}

sub _flip_URL {
  my( $transcript, $code ) = @_;
  return sprintf '/%s/%s?transcript=%s;db=%s;%s', $transcript->species, $transcript->script, $transcript->stable_id, $transcript->get_db, $code;
}

sub family {
  my( $panel, $object ) = @_;
  my $pepdata  = $object->translation_object;
  return unless $pepdata;
  my $families = $pepdata->get_family_links($pepdata);
  return unless %$families;

  my $label = 'Protein Family';
  my $html;
  foreach my $family_id (keys %$families) {
    my $family_url   = "/@{[$object->species]}/familyview?family=$family_id";
    my $family_count = $families->{$family_id}{'count'};
    my $family_desc  = $families->{$family_id}{'description'};
    $html .= qq(<p>
      <a href="$family_url">$family_id</a> : $family_desc<br />
            This cluster contains $family_count Ensembl gene member(s) in this species.</p>);
  }
  $panel->add_row( $label, $html );
}

sub interpro {
  my( $panel, $object ) = @_;
  my $trans         = $object->transcript;
  my $pepdata       = $object->translation_object;
  return unless $pepdata;
  my $interpro_hash = $pepdata->get_interpro_links( $trans );
  return unless (%$interpro_hash);
  my $label = 'InterPro';
# add table call here
  my $html = qq(<table cellpadding="4">);
  for my $accession (keys %$interpro_hash){
    my $interpro_link = $object->get_ExtURL_link( $accession, 'INTERPRO',$accession);
    my $desc = $interpro_hash->{$accession};
    $html .= qq(
  <tr>
    <td>$interpro_link</td>
    <td>$desc - [<a href="/@{[$object->species]}/domainview?domainentry=$accession">View other genes with this domain</a>]</td>
  </tr>);
  }
  $html .= qq( </table> );
  $panel->add_row( $label, $html );
}

sub transcript_structure {
  my( $panel, $transcript ) = @_;
  my $label    = 'Transcript structure';
  my $transcript_slice = $transcript->Obj->feature_Slice;
     $transcript_slice = $transcript_slice->invert if $transcript_slice->strand < 1; ## Put back onto correct strand!
  my $wuc = $transcript->get_imageconfig( 'geneview' );
     $wuc->{'_draw_single_Transcript'} = $transcript->Obj->stable_id;
     $wuc->{'_no_label'} = 'true';
     $wuc->set( 'ruler', 'str', $transcript->Obj->strand > 0 ? 'f' : 'r' );
     $wuc->set( $transcript->default_track_by_gene,'on','on');

  my $image    = $transcript->new_image( $transcript_slice, $wuc, [] );
  $panel->add_row( $label, '<div style="margin: 10px 0px">'.$image->render.'</div>' );
}

sub transcript_neighbourhood {
  my( $panel, $transcript ) = @_;
  my $label    = 'Transcript neigbourhood';
  my $transcript_slice = $transcript->Obj->feature_Slice; 
     $transcript_slice = $transcript_slice->invert if $transcript_slice->strand < 1; ## Put back onto correct strand!
     $transcript_slice = $transcript_slice->expand( 10e3, 10e3 );
  my $wuc = $transcript->get_imageconfig( 'transview' );
     $wuc->{'_no_label'} = 'true';
     $wuc->{'_add_labels'} = 'true';
     $wuc->set( 'ruler', 'str', $transcript->Obj->strand > 0 ? 'f' : 'r' );
     $wuc->set( $transcript->default_track_by_gene,'on','on');

  my $image    = $transcript->new_image( $transcript_slice, $wuc, [] );
     $image->imagemap = 'yes';
  $panel->add_row( $label, '<div style="margin: 10px 0px">'.$image->render.'</div>' );
}

sub protein_features_geneview {
  protein_features( @_, 'nosnps' );
}
sub protein_features {
  my( $panel, $transcript, $snps ) = @_;
  my $label    = 'Protein features';
  my $translation = $transcript->translation_object;
  return undef unless $translation;
  $translation->Obj->{'image_snps'}   = $translation->pep_snps unless $snps eq 'nosnps';
  $translation->Obj->{'image_splice'} = $translation->pep_splice_site( $translation->Obj );
  $panel->timer_push( "Got snps and slices for protein_feature....", 1 );

  my $wuc = $transcript->get_imageconfig( 'protview' );
  $wuc->container_width( $translation->Obj->length );
  my $image    = $transcript->new_image( $translation->Obj, $wuc, [], 1 );
     $image->imagemap = 'yes';
  $panel->add_row( $label, '<div style="margin: 10px 0px">'.$image->render.'</div>' );
  return 1;
}

sub marked_up_seq_form {
  my( $panel, $object ) = @_;
  my $form = EnsEMBL::Web::Form->new( 'marked_up_seq', "/@{[$object->species]}/transview", 'get' );
  $form->add_element( 'type' => 'Hidden', 'name' => 'db',         'value' => $object->get_db    );
  $form->add_element( 'type' => 'Hidden', 'name' => 'transcript', 'value' => $object->stable_id );
  my $show = [
    { 'value' => 'plain',   'name' => 'Exons' },
#    { 'value' => 'revcom',  'name' => 'Reverse complement sequence' },
    { 'value' => 'codons',  'name' => 'Exons and Codons' },
    { 'value' => 'peptide', 'name' => 'Exons, Codons and Translation'},
  ];
  if( $object->species_defs->databases->{'DATABASE_VARIATION'} ||
      $object->species_defs->databases->{'ENSEMBL_GLOVAR'} ) {
    push @$show, { 'value' => 'snps', 'name' => 'Exons, Codons, Translations and SNPs' };
    push @$show, { 'value' => 'snp_coding', 'name' => 'Exons, Codons, Translation, SNPs and Coding sequence'};
  }
  else {
    push @$show, { 'value' => 'coding', 'name' => 'Exons, Codons, Translation and Coding sequence'};
  }
  push @$show, { 'value'=>'rna', 'name' => 'Exons, RNA information' } if $object->Obj->biotype =~ /RNA/;
  $form->add_element(
    'type' => 'DropDown', 'name' => 'show', 'value' => $object->param('show') || 'plain',
    'values' => $show, 'label' => 'Show the following features:', 'select' => 'select'
  );
  my $number = [{ 'value' => 'on', 'name' => 'Yes' }, {'value'=>'off', 'name'=>'No' }];
  $form->add_element(
    'type' => 'DropDown', 'name' => 'number', 'value' => $object->param('number') || 'off',
    'values' => $number, 'label' => 'Number residues:', 'select' => 'select'
  );
  $form->add_element( 'type' => 'Submit', value => 'Refresh' );
  return $form;
}

sub marked_up_seq {
  my( $panel, $object ) = @_;
  my $label = "Transcript sequence";
  my $HTML = "<pre>@{[ do_markedup_pep_seq( $object ) ]}</pre>";
  my $db        = $object->get_db() ;
  my $stable_id = $object->stable_id;
  my $trans_id  = $object->transcript->stable_id;
  my $show      = $object->param('show');

  if( $show eq 'codons' ) {
      $HTML .= qq(<img src="/img/help/transview-key1.gif" height="200" width="200" alt="[Key]" border="0" />);
  } elsif( $show eq 'snps' or $show eq 'snp_coding' ) {
      $HTML .= qq(<img src="/img/help/transview-key3.gif" height="350" width="300" alt="[Key]" border="0" />);
  } elsif( $show eq 'peptide' or $show eq 'coding' ) { 
    $HTML .= qq(<img src="/img/help/transview-key2.gif" height="200" width="200" alt="[Key]" border="0" />);
  }
  elsif ($show eq 'revcom') {
    $HTML .= "<p>Reverse complement sequence</p>";
  }
  $HTML .= "<div>@{[ $panel->form( 'markup_up_seq' )->render ]}</div>";
  $panel->add_row( $label, $HTML );
  return 1;
}

sub do_markedup_pep_seq {
  my $object = shift;
  my $show = $object->param('show');
  my $number = $object->param('number');

  if( $show eq 'plain' ) {
    my $fasta = $object->get_trans_seq;
    $fasta =~ s/([acgtn\*]+)/'<span style="color: blue">'.uc($1).'<\/span>'/eg;
    return $fasta;
  } 
  elsif( $show eq 'revcom' ) {
    my $fasta = $object->get_trans_seq("revcom");
    $fasta =~ s/([acgtn\*]+)/'<span style="color: blue">'.uc($1).'<\/span>'/eg;
    return $fasta;
  }
  elsif( $show eq 'rna' ) {
    my @strings = $object->rna_notation;
    my @extra_array;
    foreach( @strings ) {
      s/(.{60})/$1\n/g;
      my @extra = split /\n/;
      if( $number eq 'on' ) {
        @extra = map { "       $_\n" } @extra;
      } else {
        @extra = map { "$_\n" } @extra;
      }
      push @extra_array, \@extra;
    }

    my @fasta = split /\n/, $object->get_trans_seq;
    my $out = '';
    foreach( @fasta ) {
      $out .= "$_\n";
      foreach my $array_ref (@extra_array) {
        $out .= shift @$array_ref; 
      }
    }
    return $out; 
  }

  # If $show ne rna or plan
  my( $cd_start, $cd_end, $trans_strand, $bps ) = $object->get_markedup_trans_seq;
  my $trans  = $object->transcript;
  my $wrap = 60;
  my $count = 0;
  my ($pep_previous, $ambiguities, $previous, $coding_previous, $output, $fasta, $peptide)  = '';
  my $coding_fasta;
  my $pos = 1;
  my $SPACER = $number eq 'on' ? '       ' : '';
  my %bg_color = (  # move to constant MARKUP_COLOUR
    'utr'      => $object->species_defs->ENSEMBL_STYLE->{'BACKGROUND1'},
    'c0'       => 'ffffff',
    'c1'       => $object->species_defs->ENSEMBL_STYLE->{'BACKGROUND2'},
    'c99'      => 'ffcc99',
    'synutr'   => '7ac5cd',
    'sync0'    => '76ee00',
    'sync1'    => '76ee00',
    'indelutr' => '9999ff',
    'indelc0'  => '99ccff',
    'indelc1'  => '99ccff',
    'snputr'   => '7ac5cd',
    'snpc0'    => 'ffd700',
    'snpc1'    => 'ffd700',
  );

  foreach(@$bps) {
    if($count == $wrap) {
      my( $NUMBER, $PEPNUM ) = ('','');
      my $CODINGNUM;
      if($number eq 'on') {
        $NUMBER = sprintf("%6d ",$pos);
        $PEPNUM = ( $pos>=$cd_start && $pos<=$cd_end ) ? sprintf("%6d ",int( ($pos-$cd_start+3)/3) ) : $SPACER ;
        $CODINGNUM = ( $pos>=$cd_start && $pos<=$cd_end ) ? sprintf("%6d ", $pos-$cd_start+1 ) : $SPACER ;
      }
      $pos += $wrap;
      $output .=  "$SPACER$ambiguities\n" if $show =~ /^snp/;
      $output .= $NUMBER.$fasta. ($previous eq '' ? '':'</span>')."\n";
      $output .="$CODINGNUM$coding_fasta".($coding_previous eq ''?'':'</span>')."\n" if $show =~ /coding/;
      $output .="$PEPNUM$peptide". ($pep_previous eq ''?'':'</span>')."\n\n" if $show =~/^snp/ || $show eq 'peptide' || $show =~ /coding/;
  
      $previous='';
      $pep_previous='';
      $coding_previous='';
      $ambiguities = '';
      $count=0;
      $peptide = '';
      $fasta ='';
      $coding_fasta ='';
    }
    my $bg = $bg_color{"$_->{'snp'}$_->{'bg'}"};
    my $style = qq(style="color: $_->{'fg'};). ( $bg ? qq( background-color: #$bg;) : '' ) .qq(");
    my $pep_style = '';
    my $coding_style;

    # SNPs
    if( $show =~ /^snp/) {
      if($_->{'snp'} ne '') {
        if( $trans_strand == -1 ) {
          $_->{'alleles'}=~tr/acgthvmrdbkynwsACGTDBKYHVMRNWS\//tgcadbkyhvmrnwsTGCAHVMRDBKYNWS\//;
          $_->{'ambigcode'} =~ tr/acgthvmrdbkynwsACGTDBKYHVMRNWS\//tgcadbkyhvmrnwsTGCAHVMRDBKYNWS\//;
        }
        $style .= qq( title="Alleles: $_->{'alleles'}");
      }
      if($_->{'aminoacids'} ne '') {
        $pep_style = qq(style="color: #ff0000" title="$_->{'aminoacids'}");
      }

      # Add links to SNPs in markup
      if ( my $url_params = $_->{'url_params'} ){ 
  $ambiguities .= qq(<a href="snpview?$url_params">).$_->{'ambigcode'}."</a>";
      } else {
        $ambiguities.= $_->{'ambigcode'};
      }
    }

    my $where =  $count + $pos;
    if($style ne $previous) {
      $fasta.=qq(</span>) unless $previous eq '';
      $fasta.=qq(<span $style>) unless $style eq '';
      $previous = $style;
    }
    if ($coding_style ne $coding_previous) {
      if ( $where>=$cd_start && $where<=$cd_end ) {
  $coding_fasta.=qq(<span $coding_style>) unless $coding_style eq '';
      }
      $coding_fasta.=qq(</span>) unless $coding_previous eq '';
      $coding_previous = $coding_style;
    }

    if($pep_style ne $pep_previous) {
      $peptide.=qq(</span>) unless $pep_previous eq '';
      $peptide.=qq(<span $pep_style>) unless $pep_style eq '';
      $pep_previous = $pep_style;
    }
    $count++;
    $fasta.=$_->{'letter'};
    $coding_fasta.=( $where>=$cd_start && $where<=$cd_end ) ? $_->{'letter'} :".";
    $peptide.=$_->{'peptide'};

  }# end foreach bp


  my( $NUMBER, $PEPNUM, $CODINGNUM)  = ("", "", "");
  if($number eq 'on') {
    $NUMBER = sprintf("%6d ",$pos);
    $CODINGNUM = ( $pos>=$cd_start && $pos<=$cd_end ) ? sprintf("%6d ", $pos-$cd_start +1 ) : $SPACER ;
    $PEPNUM = ( $pos>=$cd_start && $pos<=$cd_end ) ? sprintf("%6d ",int( ($pos-$cd_start-1)/3 +1) ) : $SPACER ;
    $pos += $wrap;
  }
      $output .=  "$SPACER$ambiguities\n" if $show =~ /^snp/;
      $output .= $NUMBER.$fasta. ($previous eq '' ? '':'</span>')."\n";
      $output .="$CODINGNUM$coding_fasta".($coding_previous eq ''?'':'</span>')."\n" if $show =~ /coding/;
      $output .="$PEPNUM$peptide". ($pep_previous eq ''?'':'</span>')."\n\n" if $show =~/^snp/ || $show eq 'peptide' || $show =~ /coding/;
#  $output .=  "$SPACER$ambiguities\n" if $show eq 'snps';
#  $output .= $NUMBER.$fasta. ($previous eq '' ? '':'</span>')."\n";
#  $output .="$CODINGNUM$coding_fasta".($coding_previous eq ''?'':'</span>')."\n" if $show eq 'coding';
#  $output .="$PEPNUM$peptide". ($pep_previous eq ''?'':'</span>')."\n\n" if $show eq 'snps' || $show eq 'peptide' || $show eq 'coding';

  return $output;
}


# Transcript SNP View ---------------------------------------###################

sub transcriptsnpview_menu    {
  my ($panel, $object) = @_;
  my $valids = $object->valids;

  my @onsources;
  map {  push @onsources, $_ if $valids->{lc("opt_$_")} }  @{$object->get_source || [] };

  my $text;
  my @populations = $object->get_samples('display');
  if ( $onsources[0] ) {
    $text = " from these sources: " . join ", ", @onsources if $onsources[0];
  }
  else {
    $text = ". Please select a source from the yellow 'Source' dropdown menu" if scalar @populations;
  }
  $panel->print("<p>Where there is resequencing coverage, SNPs have been called using a computational method.  Here we display the SNP calls observed by transcript$text.  </p>");

  my $image_config = $object->image_config_hash( 'TSV_sampletranscript' );
  $image_config->{'Populations'}    = \@populations;


  my $individual_adaptor = $object->Obj->adaptor->db->get_db_adaptor('variation')->get_IndividualAdaptor;
  $image_config->{'snp_haplotype_reference'}    =  $individual_adaptor->get_reference_strain_name();

  my $strains = ucfirst($object->species_defs->translate("strain"))."s";

  return 0;
}
# PAGE DUMP METHODS -------------------------------------------------------

sub dump {
  my ( $panel, $object ) = @_;
  my $strain = $object->species_defs->translate("strain");
  $panel->print("<p>Dump of SNP data per $strain (SNPs in rows, $strain","s in columns).  For more advanced data queries use <a href='/biomart/martview'>BioMart</a>. </p>");
  my $html = qq(
   <div>
     @{[ $panel->form( 'dump_form' )->render() ]}
  </div>);

  $panel->print( $html );
  return 1;
}


sub dump_form {
  my ($panel, $object ) = @_;

  my $form = EnsEMBL::Web::Form->new('tsvview_form', "/@{[$object->species]}/transcriptsnpdataview", 'get' );

  my  @formats = ( {"value" => "astext",  "name" => "Text format"},
        #          {"value" => "asexcel", "name" => "In Excel format"},
                   {"value" => "ashtml",  "name" => "HTML format"}
                 );

  return $form unless @formats;
  $form->add_element( 'type'  => 'Hidden',
                      'name'  => '_format',
                      'value' => 'ashtml' );
  $form->add_element(
    'class'     => 'radiocheck1col',
    'type'      => 'DropDown',
    'renderas'  => 'checkbox',
    'name'      => 'dump',
    'label'     => 'Dump format',
    'values'    => \@formats,
    'value'     => $object->param('dump') || 'astext',
  );

  $form->add_element (
                           'type'      => 'Hidden',
                           'name'      => 'transcript',
                           'value'     => $object->param('transcript'),
         );

  my @cgi_params = @{$panel->get_params($object, {style =>"form"}) };
  foreach my $param ( @cgi_params) {
       $form->add_element (
                          'type'      => 'Hidden',
                          'name'      => $param->{'name'},
                          'value'     => $param->{'value'},
                          'id'        => "Other param",
                         );
  }


 $form->add_element(
    'type'      => 'Submit',
    'name'      => 'submit',
    'value'     => 'Dump',
                    );

=pod
## TODO - Replace this inline javascript with a class name and function
  $form->add_attribute( 'onSubmit',
  qq(this.elements['_format'].value='HTML';this.target='_self';flag='';for(var i=0;i<this.elements['dump'].length;i++){if(this.elements['dump'][i].checked){flag=this.elements['dump'][i].value;}}if(flag=='astext'){this.elements['_format'].value='Text';this.target='_blank'}if(flag=='gz'){this.elements['_format'].value='Text';})
    );
=cut

  return $form;
}


sub html_dump {
  my( $panel, $object ) = @_;

  my $view_config = $object->get_viewconfig;
  $view_config->reset;
  foreach my $param ( $object->param() ) {
    $view_config->set($param, $object->param($param) , 1);
  }
  # $view_config->save;
  my @samples = sort ( $object->get_samples );

  my $snp_data = get_page_data($panel, $object, \@samples );
  unless (ref $snp_data eq 'HASH') {
    $panel->print("<p>No data in this region.");
    return;
  }

  $panel->print("<p>Format: tab separated per strain (SNP id; Type; Amino acid change;)</p>\n");
  my $header_row = join "</th><th>", ("bp position", @samples);
  $panel->print("<table class='ss tint'>\n");
  $panel->print("<tr><th>$header_row</th></tr>\n");

  my @background = ('class="bg2"', ""); 
  my $image_config = $object->image_config_hash( 'genesnpview_snps' );
  my %colours = $image_config->{'_colourmap'}->colourSet('variation');

  foreach my $snp_pos ( sort keys %$snp_data ) {
    my $background= shift @background;
    push @background, $background;
    $panel->print(qq(<tr $background><td>$snp_pos</td>));
    foreach my $sample ( @samples ) {
      my @info;
      my $style;

      foreach my $row ( @{$snp_data->{$snp_pos}{$sample} || [] } ) {
  (my $type = $row->{consequence}) =~ s/\(Same As Ref. Assembly\)//;
  if ($row->{ID}) {
    if ($row->{aachange} ne "-") {
      my $colour = $image_config->{'_colourmap'}->hex_by_name($colours{$type}[0]);
      $style = qq(style="background-color:#$colour");
    }
    push @info, "$row->{ID}; $type; $row->{aachange};";
  }
  else {
    push @info, "<td>.</td>";
  }
      }
      my $print = join "<br />", @info;
      $panel->print("<td $style>$print</td>");
    }
    $panel->print("</tr>\n");
  }
  $panel->print("\n</table>");
  return 1;
}

sub text_dump {
  my( $panel, $object ) = @_;

  my $view_config = $object->get_viewconfig;
  $view_config->reset;
  foreach my $param ( $object->param() ) {
    $view_config->set($param, $object->param($param) , 1);
  }
  # $view_config->save;
  my @samples = sort ( $object->get_samples );
  $panel->print("Variation data for ".$object->stable_id);
  $panel->print("\nFormat: tab separated per strain (SNP id; Type; Amino acid change;)\n\n");

  my $snp_data = get_page_data($panel, $object, \@samples );
  unless (ref $snp_data eq 'HASH') {
    $panel->print("No data in this region.");
    return;
  }

  my $header_row = join "\t", ("bp position", @samples);
  $panel->print("$header_row\n");

  foreach my $snp_pos ( sort keys %$snp_data ) {
    $panel->print(qq($snp_pos\t));
    foreach my $sample ( @samples ) {
      foreach my $row ( @{$snp_data->{$snp_pos}{$sample} || [] }) {
  (my $type = $row->{consequence}) =~ s/\(Same As Ref. Assembly\)//;;
  my $info = $row->{ID} ? "$row->{ID}; $type; $row->{aachange}; " : ".";
  $panel->print(qq($info));
      }
      $panel->print("\t");
    }
    $panel->print("\n");
  }
  $panel->print("\n");
  return 1;
}

sub EC_URL {
  my( $self,$string ) = @_;
  my $URL_string= $string;
  $URL_string=~s/-/\?/g;
  return $self->object->get_ExtURL_link( "EC $string", 'EC_PATHWAY', $URL_string );
}

1;
