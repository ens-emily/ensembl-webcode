=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

=head1 NAME

Bio::Tools::Run::Search::ensembl_wutblastn - Ensembl TBLASTN searches

=head1 SYNOPSIS

  see Bio::Tools::Run::Search::EnsemblBlast
  see Bio::Tools::Run::Search::wutblastn

=head1 DESCRIPTION

Multiple inheretance object combining
Bio::Tools::Run::Search::EnsemblBlast and
Bio::Tools::Run::Search::wutblastn

=cut

# Let the code begin...
package Bio::Tools::Run::Search::ensembl_wutblastn;
use strict;

use vars qw( @ISA );

use Bio::Tools::Run::Search::EnsemblBlast;
use Bio::Tools::Run::Search::wutblastn;

@ISA = qw( Bio::Tools::Run::Search::EnsemblBlast 
           Bio::Tools::Run::Search::wutblastn );

BEGIN{
}

# Nastyness to get round multiple inheretance problems.
sub program_name{return Bio::Tools::Run::Search::wutblastn::program_name(@_)}
sub algorithm   {return Bio::Tools::Run::Search::wutblastn::algorithm(@_)}
sub version     {return Bio::Tools::Run::Search::wutblastn::version(@_)}
sub parameter_options{
  return Bio::Tools::Run::Search::wutblastn::parameter_options(@_)
}

#----------------------------------------------------------------------
1;
