=head1 LICENSE
Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
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
use strict;
use warnings;

use Test::More;
use Bio::EnsEMBL::Test::MultiTestDB;
use Bio::EnsEMBL::Test::TestUtils;

my $multi = Bio::EnsEMBL::Test::MultiTestDB->new('homo_sapiens');

my $g2pdb = $multi->get_DBAdaptor('gene2phenotype');

my $gfdpa = $g2pdb->get_GenomicFeatureDiseasePublicationAdaptor;
my $gfda = $g2pdb->get_GenomicFeatureDiseaseAdaptor;

ok($gfdpa && $gfdpa->isa('Bio::EnsEMBL::G2P::DBSQL::GenomicFeatureDiseasePublicationAdaptor'), 'isa GenomicFeatureDiseasePublicationAdaptor');

my $GFDP_id = 455;

my $GFDP = $gfdpa->fetch_by_dbID($GFDP_id);
ok($GFDP->dbID == $GFDP_id, 'fetch_by_dbID');

my $GFD_id = 204;
my $publication_id = 1407;
$GFDP = $gfdpa->fetch_by_GFD_id_publication_id($GFD_id, $publication_id);
ok($GFDP->dbID == $GFDP_id, 'fetch_by_GFD_id_publication_id');

my $GFD = $gfda->fetch_by_dbID($GFD_id);
my $GFDPs = $gfdpa->fetch_all_by_GenomicFeatureDisease($GFD);
ok(scalar @$GFDPs == 6, 'fetch_all_by_GenomicFeatureDisease');

done_testing();
1;
