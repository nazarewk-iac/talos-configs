- the most important/missing setting is `spec.network.dualStack`,
  works fine with host networking and Cilium, but
  had trouble switching Host -> Cilium
- skipped Erasure Coding to make it easier on the (scarce) CPU.

- [ ] TODO: add topologies to nodes and re-join nodes?
- [ ] TODO: for Ceph Filesystem the active MDS node spams `parse_caps: cannot decode auth caps buffer of length 0` hundreds times per second
