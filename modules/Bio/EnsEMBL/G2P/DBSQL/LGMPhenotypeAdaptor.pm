=head1 LICENSE
 
See the NOTICE file distributed with this work for additional information
regarding copyright ownership.
 
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

package Bio::EnsEMBL::G2P::DBSQL::LGMPhenotypeAdaptor;

use Bio::EnsEMBL::G2P::LGMPhenotype;
use DBI qw(:sql_types);

our @ISA = ('Bio::EnsEMBL::G2P::DBSQL::BaseAdaptor');

sub store {
  my $self = shift;
  my $lgm_phenotype = shift;

  if (!ref($lgm_phenotype) || !$lgm_phenotype->isa('Bio::EnsEMBL::G2P::LGMPhenotype')) {
    die('Bio::EnsEMBL::G2P::LGMPhenotype arg expected');
  }

  my $dbh = $self->dbc->db_handle;

  my $sth = $dbh->prepare(q{
    INSERT INTO LGM_phenotype(
      locus_genotype_mechanism_id,
      phenotype_id,
      user_id,
      created
    ) VALUES (?, ?, ?, CURRENT_TIMESTAMP)
  });

  $sth->execute(
    $lgm_phenotype->locus_genotype_mechanism_id,
    $lgm_phenotype->phenotype_id,
    $lgm_phenotype->user_id
  );

  $sth->finish();
  
  my $dbID = $dbh->last_insert_id(undef, undef, 'LGM_phenotype', 'LGM_phenotype_id'); 
  $lgm_phenotype->{LGM_phenotype_id} = $dbID;

  return $lgm_phenotype;
}

sub fetch_all {
  my $self = shift;
  return $self->generic_fetch();
}

sub fetch_by_LocusGenotypeMechanism_Phenotype {
  my $self = shift;
  my $locus_genotype_mechanism = shift;
  my $phenotype = shift;
  my $locus_genotype_mechanism_id = $locus_genotype_mechanism->dbID;
  my $phenotype_id = $phenotype->dbID;
  my $constraint = "locus_genotype_mechanism_id=$locus_genotype_mechanism_id AND phenotype_id=$phenotype_id;";
  my $result = $self->generic_fetch($constraint);
  return $result->[0];
}

sub fetch_all_by_LocusGenotypeMechanism {
  my $self = shift;
  my $locus_genotype_mechanism = shift;
  my $locus_genotype_mechanism_id = $locus_genotype_mechanism->dbID;
  my $constraint = "locus_genotype_mechanism_id=$locus_genotype_mechanism_id;";
  return $self->generic_fetch($constraint);
}

sub _columns {
  my $self = shift;
  my @cols = (
    'LGM_phenotype_id',
    'locus_genotype_mechanism_id',
    'phenotype_id',
    'user_id',
    'created',
  );
  return @cols;
}

sub _tables {
  my $self = shift;
  my @tables = (
    ['LGM_phenotype'],
  );
  return @tables;
}

sub _objs_from_sth {
  my ($self, $sth) = @_;
  my ($LGM_phenotype_id, $locus_genotype_mechanism_id, $phenotype_id, $user_id, $created);
  $sth->bind_columns(\($LGM_phenotype_id, $locus_genotype_mechanism_id, $phenotype_id, $user_id, $created));

  my @objs;

  while ($sth->fetch()) {
    my $obj = Bio::EnsEMBL::G2P::LGMPhenotype->new(
      -LGM_phenotype_id => $LGM_phenotype_id,
      -locus_genotype_mechanism_id => $locus_genotype_mechanism_id,
      -phenotype_id => $phenotype_id,
      -user_id => $user_id,
      -created => $created,
      -adaptor => $self,
    );
    push(@objs, $obj);
  }
  return \@objs;
}

1;
