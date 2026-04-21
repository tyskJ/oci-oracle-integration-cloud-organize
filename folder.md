# フォルダ構成

- フォルダ構成は以下の通り

```
.
├── deploy_com_stop_functions.rst     Compute Instance 停止用Functionsデプロイ手順
├── deploy_waf_close_functions.rst    WAF Request Access Rules Default Action を固定レスポンスに変更するFunctionsデプロイ手順
└── envs
    ├── backend.tf                    tfstateファイル管理定義ファイル
    ├── bastion.tf                    Bastion定義ファイル
    ├── compartments.tf               デプロイ用コンパートメント定義ファイル
    ├── compute_linux.tf              Compute(Oracle Linux)定義ファイル
    ├── config
    │   └── sorry_page.html           固定レスポンス用HTMLファイル
    ├── container_registry.tf         Container Registry定義ファイル
    ├── data.tf                       外部データソース定義ファイル
    ├── elb.tf                        FLB定義ファイル
    ├── functions.tf                  Functions定義ファイル
    ├── iam.tf                        IAM定義ファイル
    ├── locals.tf                     ローカル変数定義ファイル
    ├── logging.tf                    Logging定義ファイル
    ├── oracle_integration_cloud.tf   Oracle Integration Cloud定義ファイル
    ├── outputs.tf                    リソース戻り値定義ファイル
    ├── providers.tf                  プロバイダー定義ファイル
    ├── python
    │   ├── compute-stop              Compute Instance 停止用コード
    │   │   ├── func.py
    │   │   ├── func.yaml
    │   │   └── requirements.txt
    │   └── waf-close                  Default Action 固定レスポンス化コード
    │       ├── func.py
    │       ├── func.yaml
    │       └── requirements.txt
    ├── tags.tf                       定義済みタグ定義ファイル
    ├── userdata
    │   └── oraclelinux_init.sh       Linux用userdataスクリプト
    ├── variables.tf                  変数定義ファイル
    ├── vcn.tf                        VCN定義ファイル
    ├── versions.tf                   Terraformバージョン定義ファイル
    └── waf.tf                        WAFポリシー定義ファイル
```
