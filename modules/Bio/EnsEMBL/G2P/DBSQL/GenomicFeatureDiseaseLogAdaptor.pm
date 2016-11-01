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

package Bio::EnsEMBL::G2P::DBSQL::GenomicFeatureDiseaseLogAdaptor;

use Bio::EnsEMBL::G2P::GenomicFeatureDiseaseLog;
use Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor;
use DBI qw(:sql_types);

our @ISA = ('Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor');

sub store {
  my $self = shift;
  my $gfd_log = shift;
  my $dbh = $self->dbc->db_handle;

  if (!ref($gfd_log) || !$gfd_log->isa('Bio::EnsEMBL::G2P::GenomicFeatureDiseaseLog')) {
    die('Bio::EnsEMBL::G2P::GenomicFeatureDiseaseLog arg expected');
  }

  my $sth = $dbh->prepare(q{
    INSERT INTO genomic_feature_disease_log(
      genomic_feature_disease_id,
      genomic_feature_id,
      disease_id,
      DDD_category_attrib,
      is_visible,
      panel_attrib,
      created,
      user_id,
      action
    ) VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, ?, ?)
  });

  $sth->execute(
    $gfd_log->{genomic_feature_disease_id},
    $gfd_log->{genomic_feature_id},
    $gfd_log->{disease_id},
    $gfd_log->DDD_category_attrib || undef,
    $gfd_log->is_visible || 1,
    $gfd_log->panel_attrib || undef,
    $gfd_log->user_id,
    $gfd_log->action,
  );

  $sth->finish();
  
  # get dbID
  my $dbID = $dbh->last_insert_id(undef, undef, 'genomic_feature_disease_log', 'genomic_feature_disease_log_id'); 
  $gfd_log->{genomic_feature_disease_log_id} = $dbID;

  return $gfd_log;
}

sub delete {
  my $self = shift;
  my $gfd_log = shift;
  my $user = shift;
  my $dbh = $self->dbc->db_handle;

  if (!ref($gfd_log) || !$gfd_log->isa('Bio::EnsEMBL::G2P::GenomicFeatureDiseaseLog')) {
    die ('Bio::EnsEMBL::G2P::GenomicFeatureDiseaseLog arg expected');
  }

  if (!ref($user) || !$user->isa('Bio::EnsEMBL::G2P::User')) {
    die ('Bio::EnsEMBL::G2P::User arg expected');
  }

  my $sth = $dbh->prepare(q{
    INSERT INTO genomic_feature_disease_log_deleted (
      genomic_feature_disease_log_id,
      genomic_feature_disease_id,
      genomic_feature_id,
      disease_id,
      DDD_category_attrib,
      is_visible,
      panel_attrib,
      created,
      user_id,
      action,
      deleted,
      deleted_by_user_id
    ) VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, ?)
  });

  $sth->execute(
    $gfd_log->dbID,
    $gfd_log->genomic_feature_id,
    $gfd_log->disease_id,
    $gfd_log->DDD_category_attrib,
    $gfd_log->is_visible,
    $gfd_log->panel_attrib,
    $gfd_log->created,
    $gfd_log->user_id,
    $user->user_id
  );
  $sth->finish();

  $sth = $dbh->prepare(q{
    DELETE FROM genomic_feature_disease_log WHERE genomic_feature_disease_log_id = ?;
  });

  $sth->execute($gfd_log->dbID);
  $sth->finish();
}

sub fetch_by_dbID {
  my $self = shift;
  my $genomic_feature_disease_id = shift;
  return $self->SUPER::fetch_by_dbID($genomic_feature_disease_id);
}

sub _columns {
  my $self = shift;
  my @cols = (
    'gfdl.genomic_feature_disease_log_id',
    'gfdl.genomic_feature_disease_id',
    'gfdl.genomic_feature_id',
    'gfdl.disease_id',
    'gfdl.DDD_category_attrib',
    'gfdl.is_visible',
    'gfdl.panel_attrib',
    'gfdl.created',
    'gfdl.user_id',
    'gfdl_action'
  );
  return @cols;
}

sub _tables {
  my $self = shift;
  my @tables = (
    ['genomic_feature_disease_log', 'gfdl'],
  );
  return @tables;
}

sub _objs_from_sth {
  my ($self, $sth) = @_;

  my ($genomic_feature_disease_log_id, $genomic_feature_disease_id, $genomic_feature_id, $disease_id, $DDD_category_attrib, $is_visible, $panel_attrib, $created, $user_id, $action);
  $sth->bind_columns(\($genomic_feature_disease_log_id, $genomic_feature_disease_id, $genomic_feature_id, $disease_id, $DDD_category_attrib, $is_visible, $panel_attrib, $created, $user_id, $action));

  my @objs;

  my $attribute_adaptor = $self->db->get_AttributeAdaptor;

  while ($sth->fetch()) {
    my $DDD_category = undef; 
    my $panel = undef; 
    if ($DDD_category_attrib) {
      $DDD_category = $attribute_adaptor->attrib_value_for_id($DDD_category_attrib);
    }
    if ($panel_attrib) {
      $panel = $attribute_adaptor->attrib_value_for_id($panel_attrib);
    }

    my $obj = Bio::EnsEMBL::G2P::GenomicFeatureDiseaseLog->new(
      -genomic_feature_disease_log_id => $genomic_feature_disease_log_id,
      -genomic_feature_disease_id => $genomic_feature_disease_id,
      -genomic_feature_id => $genomic_feature_id,
      -disease_id => $disease_id,
      -DDD_category => $DDD_category, 
      -DDD_category_attrib => $DDD_category_attrib,
      -is_visible => $is_visible,
      -panel => $panel,
      -panel_attrib => $panel_attrib,
      -created => $created,
      -user_id => $user_id,
      -adaptor => $self,
    );
    push(@objs, $obj);
  }
  return \@objs;
}

1;