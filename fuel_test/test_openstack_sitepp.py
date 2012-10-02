from devops.helpers import ssh
from base import RecipeTestCase
from helpers import execute
from settings import NODES
from root import root

import unittest

class OpenStackSitePPCase(RecipeTestCase):

    def setUp(self):
        super(OpenStackSitePPCase, self).setUp()
        self.controller1 = self.environment.node[NODES[0]]
        self.controller2 = self.environment.node[NODES[1]]
        self.compute1 = self.environment.node[NODES[2]]
        self.compute2 = self.environment.node[NODES[3]]

    def test_deploy_nova_compute(self):
        self.validate(
            [self.compute1,],
            'puppet agent --test --tags openstack::repo::yum,%s' % "nova::compute")

    def test_deploy_nova_api_compute(self):
        self.validate(
            [self.compute1,],
            'puppet agent --test --tags openstack::repo::yum,%s' % "nova::api")

    def test_deploy_nova_api_controller(self):
        self.validate(
            [self.controller1,],
            'puppet agent --test --tags openstack::repo::yum,%s' % "nova::api")

    def test_deploy_nova_network(self):
        self.validate(
            [self.compute1, ],
            'puppet agent --test --tags openstack::repo::yum,%s' % "nova::network")

    def test_deploy_nova_consoleauth(self):
        self.validate(
            [self.controller1, self.controller2],
            'puppet agent --test --tags openstack::repo::yum,%s' % "nova::consoleauth")


    def test_deploy_nova_rabbitmq(self):
        self.validate(
            [self.controller1, self.controller2],
            'puppet agent --test --tags openstack::repo::yum,%s' % "nova::rabbitmq")

    def test_deploy_nova_utilities(self):
        self.validate(
            [self.compute1, ],
            'puppet agent --test --tags openstack::repo::yum,%s' % "nova::utilities")

    def test_deploy_nova_vncproxy(self):
        self.validate(
            [self.controller1, ],
            'puppet agent --test --tags openstack::repo::yum,%s' % "nova::vncproxy")

    def test_deploy_nova_volume(self):
        self.validate(
            [self.compute1, ],
            'puppet agent --test --tags openstack::repo::yum,%s' % "nova::volume")


    def write_openstack_sitepp(self, node01, node02):
        internal_virtual_ip = self.environment.network['internal'].ip_addresses[
                              -3]
        public_virtual_ip = self.environment.network['public'].ip_addresses[-3]
        self.write_site_pp_manifest(
            root('fuel', 'deployment', 'puppet', 'openstack', 'examples',
                'site.pp'),
            internal_virtual_ip="'%s'" % internal_virtual_ip,
            public_virtual_ip="'%s'" % public_virtual_ip,
            master_hostname="'%s'" % node01.name,
            controller_public_addresses=[
                "%s" % node01.ip_address_by_network['public'],
                "%s" % node02.ip_address_by_network['public']
            ],
            controller_internal_addresses=[
                "%s" % node01.ip_address_by_network['internal'],
                "%s" % node02.ip_address_by_network['internal']
            ],
            controller_hostnames=[
                "%s" % node01.name,
                "%s" % node02.name],
            public_interface="'eth2'",
            internal_interface="'eth0'",
            internal_address="$ipaddress_eth0",
            private_interface="'eth1'"
        )

    def do(self, nodes, command):
        self.write_openstack_sitepp(self.controller1, self.controller2)
        results = []
        for node in nodes:
            remote = ssh(node.ip_address, username='root', password='r00tme')
            results.append(execute(remote.sudo.ssh, command))
        return results

    def validate(self, nodes, command):
        results = self.do(nodes, command)
        for result in results:
            self.assertResult(result)

if __name__ == '__main__':
    unittest.main()