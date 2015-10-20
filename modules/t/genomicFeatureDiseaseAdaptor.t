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

my $gfda = $g2pdb->get_GenomicFeatureDiseaseAdaptor;
my $da = $g2pdb->get_DiseaseAdaptor;
my $gfa = $g2pdb->get_GenomicFeatureAdaptor;
my $ua = $g2pdb->get_UserAdaptor;

ok($gfda && $gfda->isa('Bio::EnsEMBL::G2P::DBSQL::GenomicFeatureDiseaseAdaptor'), 'isa GenomicFeatureDiseaseAdaptor');

my $disease_id = 85;
my $disease = $da->fetch_by_dbID($disease_id);
ok($disease->dbID == $disease_id, 'disease');
my $genomic_feature_id = 1252;
my $genomic_feature = $gfa->fetch_by_dbID($genomic_feature_id);
ok($genomic_feature->dbID == $genomic_feature_id, 'genomic_feature');
my $panel = 'DD'; 

my $gfds = $gfda->fetch_all_by_GenomicFeature($genomic_feature);
ok(scalar @$gfds == 9, 'fetch_all_by_GenomicFeature');

$gfds = $gfda->fetch_all_by_GenomicFeature_panel($genomic_feature, $panel);
ok(scalar @$gfds == 9, 'fetch_all_by_GenomicFeature_panel');

$gfds = $gfda->fetch_all_by_Disease($disease);
ok(scalar @$gfds == 1, 'fetch_all_by_Disease');
$gfds = $gfda->fetch_all_by_Disease_panel($disease, $panel);
ok(scalar @$gfds == 1, 'fetch_all_by_Disease_panel');

my $gfd = $gfda->fetch_by_GenomicFeature_Disease($genomic_feature, $disease);
ok($gfd->get_Disease->name eq 'SPONDYLOEPIPHYSEAL DYSPLASIA CONGENITA; SEDC', 'fetch_by_GenomicFeature_Disease');
ok($gfd->get_GenomicFeature->gene_symbol eq 'COL2A1', 'fetch_by_GenomicFeature_Disease');

my $gfd_id = 1860;
$gfd = $gfda->fetch_by_dbID($gfd_id);
ok($gfd->dbID == $gfd_id, 'fetch_by_dbID');

$gfds = $gfda->fetch_all_by_disease_id($disease_id);
ok(scalar @$gfds == 1, 'fetch_all_by_disease_id');

$gfds = $gfda->fetch_all();
ok(scalar @$gfds == 9, 'fetch_all');

# store and update
$disease = Bio::EnsEMBL::G2P::Disease->new(
  -name => 'test_GFD_disease',
);
$da->store($disease);
$disease_id = $disease->{disease_id};
$genomic_feature_id = 1252;
my $DDD_category_attrib = 32;
my $is_visible = 1;
$panel = 38;

my $user = $ua->fetch_by_dbID(1);

$gfd = Bio::EnsEMBL::G2P::GenomicFeatureDisease->new(
  -genomic_feature_id => $genomic_feature_id,
  -disease_id => $disease_id,
  -DDD_category_attrib => $DDD_category_attrib,
  -is_visible => $is_visible,
  -panel => $panel,
  -adaptor => $gfda,
);

ok($gfda->store($gfd, $user), 'store');

my $GFD_id = $gfd->{genomic_feature_disease_id};

$gfd = $gfda->fetch_by_dbID($GFD_id);
$gfd->DDD_category('possible DD gene');
ok($gfda->update($gfd, $user), 'update');

$gfd = $gfda->fetch_by_dbID($GFD_id);
ok($gfd->DDD_category eq 'possible DD gene', 'test update');

my $dbh = $gfda->dbc->db_handle;
$dbh->do(qq{DELETE FROM genomic_feature_disease WHERE disease_id=$disease_id;}) or die $dbh->errstr;
$dbh->do(qq{DELETE FROM disease WHERE disease_id=$disease_id;}) or die $dbh->errstr;

done_testing();
1;

