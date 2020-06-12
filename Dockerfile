FROM registry.access.redhat.com/ubi8
LABEL maintainer="Jason Horn (Red Hat)"

RUN curl -sL https://api.github.com/repos/bitnami-labs/sealed-secrets/releases/latest \
| grep "browser_download_url" | cut -d : -f 2,3 | tr -d '"' |grep linux | xargs curl -sL -o /usr/local/bin/kubeseal \
&& chmod +x /usr/local/bin/kubeseal


RUN curl -k -s https://mirror.openshift.com/pub/openshift-v4/clients/oc/latest/linux/oc.tar.gz -o oc.tar.gz \
&& tar -xvzf oc.tar.gz -C /usr/local/bin/ && rm oc.tar.gz

RUN curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash \
&& mv kustomize /usr/local/bin

RUN yum --disableplugin=subscription-manager -y install git  \
  && yum --disableplugin=subscription-manager clean all
ENTRYPOINT ["/bin/bash"]
