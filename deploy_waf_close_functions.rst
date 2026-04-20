WAF Request Access Rule Default Action を 固定レスポンス に変更するFunctionsデプロイ
=====================================================================
.. note::

  * ``CloudShell (Public Network)`` にて実行します
  * CPU アーキテクチャは ``x86_64`` に変更してください (本環境のfunctions application を ``x86_64`` でデプロイしているため)

1. ``context`` アップデート
---------------------------------------------------------------------
1-1. ``functions region`` アップデート
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. code-block:: bash

  fn use context ap-tokyo-1

1-2. ``functions compartment ID`` アップデート
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. code-block:: bash

  COMPARTMENT_NAME="oci-oracle-integration-cloud-organize"
  COMPARTMENT_ID=$(oci iam compartment list \
    --lifecycle-state ACTIVE \
    --query "data[?name=='${COMPARTMENT_NAME}'].id | [0]" \
    --raw-output)

.. code-block:: bash

  fn update context oracle.compartment-id "${COMPARTMENT_ID}"

1-3. ``functions image deploy repository`` アップデート
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. code-block:: bash

  TENANCY_ID=$(oci iam compartment list \
    --lifecycle-state ACTIVE \
    --include-root \
    --query "data[?\"compartment-id\"==null].id | [0]" \
    --raw-output)

.. code-block:: bash

  NAMESPACE=$(oci os ns get \
    --compartment-id "${TENANCY_ID}" \
    --query "data" \
    --raw-output)

.. code-block:: bash

  REPO_PREFIX="waf_close_mngt"
  fn update context registry nrt.ocir.io/${NAMESPACE}/${REPO_PREFIX}

2. ``OCIR`` へログイン
---------------------------------------------------------------------
.. note::

  * ``WORK_USERNAME`` の値は、デプロイ時に指定したユーザー名に変更して実行してください
  * ``AUTH_TOKEN`` の値は ``envs/.key/work_user_auth_token.txt`` に記載の値に変更して実行してください

.. code-block:: bash

  TENANCY_ID=$(oci iam compartment list \
    --lifecycle-state ACTIVE \
    --include-root \
    --query "data[?\"compartment-id\"==null].id | [0]" \
    --raw-output)

.. code-block:: bash

  NAMESPACE=$(oci os ns get \
    --compartment-id "${TENANCY_ID}" \
    --query "data" \
    --raw-output)

.. code-block:: bash

  WORK_USERNAME="作業IAMユーザー名"
  AUTH_TOKEN="認証トークン"
  docker login -u "${NAMESPACE}/${WORK_USERNAME}" nrt.ocir.io -p "${AUTH_TOKEN}"

3. 関数の作成
---------------------------------------------------------------------
3-1. 関数初期化
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.. code-block:: bash

  FN_NAME="waf-close"
  fn init --runtime python ${FN_NAME}

3-2. コード修正
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
* ``~/waf-close`` 配下の各種ファイルの中身を `本フォルダ配下のファイルの中身 <./envs/python/waf-close>`_ に置き換えてください

4. 関数のデプロイ
---------------------------------------------------------------------
.. code-block:: bash

  APP_NAME="waf-close"
  FN_NAME="waf-close"
  cd ~/${FN_NAME}
  fn -v deploy --app ${APP_NAME}

.. note::

  * デプロイする度に、``func.yaml`` の ``version`` が増えていきます

5. 実行
---------------------------------------------------------------------
.. code-block:: bash

  APP_NAME="waf-close"
  FN_NAME="waf-close"
  cd ~/${FN_NAME}
  fn invoke ${APP_NAME} ${FN_NAME}