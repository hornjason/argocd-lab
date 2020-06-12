FROM registry.access.redhat.com/ubi8
LABEL maintainer="Jason Horn (Red Hat)"

RUN curl -k -s  https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.12.2/kubeseal-linux-amd64 -o /usr/local/bin/kubeseal
RUN chmod 755 /usr/local/bin/kubeseal
RUN curl -k -s https://mirror.openshift.com/pub/openshift-v4/clients/oc/latest/linux/oc.tar.gz -o oc.tar.gz && tar -xvzf oc.tar.gz -C /usr/local/bin/
RUN yum --disableplugin=subscription-manager -y install git  \
  && yum --disableplugin=subscription-manager clean all
ENTRYPOINT ["/bin/bash"]
