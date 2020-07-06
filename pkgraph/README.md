## Pkgraph - graphs of Nimble package dependencies




Cypher queries:

```cypher
match (p1: package)-[:authored_by]->(other_author: author)
match (p1)-[:depends_on*]->(p2:package)-[:authored_by]->(main_author:author {name: 'Andreas Rumpf'})
optional match (p3:package)-[:authored_by]->(main_author)
return *
```

```cypher
match (p: package)-[:authored_by]->(a: author {name: 'Andreas Rumpf'})
optional match (p2)-[:depends_on*]->(p)
optional match (p2)-[:authored_by]->(a2)
with a, a2, p, p2, collect(p) as orig_pkgs, collect(p2) as rel_pkgs
return a, orig_pkgs, a2, rel_pkgs
```

```cypher
match (p: package)-[:authored_by]->(a: author {name: 'Andreas Rumpf'})
optional match (p2)-[:depends_on*]->(p)
optional match (p2)-[:authored_by]->(a2)
return *
```

```cypher
match m1 = (p: package)-[r:authored_by]->(a: author {name: 'Andreas Rumpf'}) with *, relationships(m1) as rels1
match m2 = (p2)-[:depends_on*]->(p) with *, relationships(m2) as rels2
match m3 = (p2)-[r2:authored_by]->(a2) with *, relationships(m3) as rels3
// return collect(a), collect(a2), collect(r), collect(r2), collect(p), collect(p2)
return count(rels1)
```

```cypher
match m1 = (p: package)-[r:authored_by]->(a: author {name: 'Andreas Rumpf'}) with *, relationships(m1) as rels1
match m2 = (p2)-[:depends_on*]->(p) with *, relationships(m2) as rels2
match m3 = (p2)-[r2:authored_by]->(a2) with *, relationships(m3) as rels3
// return collect(a), collect(a2), collect(r), collect(r2), collect(p), collect(p2)
return count(p)
```

```cypher
match (p: package)-[r:authored_by]->(a: author {name: 'Andreas Rumpf'})
// return collect(a), collect(a2), collect(r), collect(r2), collect(p), collect(p2)
return count(distinct p)
```

```cypher
match (p1: package)-[:authored_by]->(a1: author {name: 'Andreas Rumpf'})
optional match (p2: package)-[:depends_on*]->(p1)
return count(distinct p1), count(distinct p2), collect(p1), a1, collect(p2), collect(a2)
```