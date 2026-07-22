---
id: "2026-07-14-firestore-schema-go"
status: "done"
priority: "medium"
assignee: null
epic: null
dueDate: null
created: "2026-07-14T14:01:19.387Z"
modified: "2026-07-22T12:46:10.839Z"
completedAt: "2026-07-22T12:46:10.839Z"
labels: []
order: "a0"
---
# Firestore schema Goコード出力先変更

server以外からも参照できるようにする。

ルート直下に、gen-goディレクトリを作って、それを参照する

## 方針の意図

- go.workは使わない。go.workを増やすと開発体験は良くなるが、リポジトリ直下に新しい概念を持ち込みたくなかった。
- gen-goをcomponent/vX.Y.Zタグでバージョン管理する案もあったが、「PRマージ→タグ発行→server/homepageのgo.modをgo getでbump→別PR」と2段階になり面倒。`replace .../gen-go => ../gen-go`でローカル参照すれば、スキーマ変更とgen再生成を1PRで完結できる。
