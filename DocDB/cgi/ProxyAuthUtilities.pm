#
#        Name: $RCSfile$
# Description: Routines to deal with shibboleth as an authentication mechanism
#
#    Revision: $Revision$
#    Modified: $Author$ on $Date$
#
#      Author: Eric Vaandering (ewv@fnal.gov)

# Copyright 2001-2013 Eric Vaandering, Lynn Garren, Adam Bryant

#    This file is part of DocDB.

#    DocDB is free software; you can redistribute it and/or modify
#    it under the terms of version 2 of the GNU General Public License
#    as published by the Free Software Foundation.

#    DocDB is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.

#    You should have received a copy of the GNU General Public License
#    along with DocDB; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA

require "SecuritySQL.pm";
require "NotificationSQL.pm";


sub FetchSecurityGroupsForProxy (%) {

  my @UsersGroupIDs = ();

  # If user is in DocDB's database, give them those groups
  my $EmailUserID = FetchEmailUserIDForProxy();
  @UsersGroupIDs = FetchUserGroupIDs($EmailUserID);

  if (@UsersGroupIDs) {
    return @UsersGroupIDs;
  }

  # Otherwise map shibboleth groups to DocDB groups

  push @DebugStack,"Setting DocDB groups from proxy groups ".$ENV{X_AUTH_PROXY_GROUPS};
  my @ProxyGroups = split /,/,$ENV{X_AUTH_PROXY_GROUPS};

  foreach my $ProxyGroup (@ProxyGroups) {
    if ($ProxyGroupMap{$ProxyGroup}) {
      foreach my $DocDBGroup (@{ $ProxyGroupMap{$ProxyGroup} }) {
        my $UsersGroupID = FetchSecurityGroupByName($DocDBGroup);
        if ($UsersGroupID) {
          push @UsersGroupIDs,$UsersGroupID;
        }
      }
    }
  }
  return @UsersGroupIDs;
}

sub FetchEmailUserIDForProxy () {
  my $ProxyName = $ENV{X_AUTH_PROXY_USER};
  push @DebugStack,"Finding EmailUserID by Proxy name $ProxyName";

  my $EmailUserSelect = $dbh->prepare("select EmailUserID from EmailUser ".
                                      "where Username=?");
  $EmailUserSelect -> execute($ProxyName);

  my ($EmailUserID) = $EmailUserSelect -> fetchrow_array;

  if (!$EmailUserID and $Preferences{Security}{AutoCreateProxy}) {
    $EmailUserID = CreateProxyUser();
  }

  if ($EmailUserID) {
    FetchEmailUser($EmailUserID)
  }

  return $EmailUserID;
}

sub CreateProxyUser() {
  my ($FQUN, $UserName, $Email, $Name) = GetUserInfoProxy();
  if ($FQUN eq 'Unknown') {
    push @DebugStack, 'Username is Unknown. Not inserting. SSO may not be set up correctly.';
    return;
  }

  push @DebugStack, "Creating Shibboleth SSO user in EmailUser with Username=$FQUN, Email=$Email, Name=$Name";
  CreateConnection(-type => "rw");   # Can't rely on connection setup by top script, may be read-only
  my $UserInsert = $dbh_rw->prepare(
      "insert into EmailUser (EmailUserID,Username,Name,EmailAddress,Password,Verified) " .
      "values                (0,          ?,       ?,   ?,           ?,       1)");
  $UserInsert->execute($FQUN, $Name, $Email, 'x');
  my $EmailUserID = $UserInsert -> {mysql_insertid}; # Works with MySQL only
  DestroyConnection($dbh_rw);
  push @DebugStack, "Created EmailUserID $EmailUserID for SSO";
  return $EmailUserID;
}

sub GetUserInfoProxy() {
  my $Username = "Unknown";
  my $EmailAddress = "Unknown";
  my $Name = "Unknown";

  if (exists $ENV{'X_AUTH_PROXY_USER'}) {
    $Name = $ENV{X_AUTH_PROXY_FULLNAME};
    $EmailAddress = $ENV{X_AUTH_PROXY_EMAIL};
    $Username = $ENV{X_AUTH_PROXY_USER};
  }

  push @DebugStack, "GetUserInfoProxy returning $Username, $Username, $EmailAddress, $Name";

  return ($Username, $Username, $EmailAddress, $Name);
}

1;
